project_dir := source_dir()
container_runtime := env_var_or_default("CONTAINER_RUNTIME", `
  if command -v podman >/dev/null 2>&1; then
    printf podman
  elif command -v docker >/dev/null 2>&1; then
    printf docker
  else
    printf 'Neither podman nor docker is available.\n' >&2
    exit 1
  fi
`)
antares_instance := env_var_or_default("ANTARES_INSTANCE", "antares")
antares_workdir := env_var_or_default("ANTARES_WORKDIR", project_dir + "/data")
antares_cpus := env_var_or_default("ANTARES_CPUS", "8")
antares_memory := env_var_or_default("ANTARES_MEMORY", "16GiB")
antares_disk_size := env_var_or_default("ANTARES_DISK_SIZE", "50GiB")
antares_timeout := env_var_or_default("ANTARES_TIMEOUT", "3600")
incus := env_var_or_default("INCUS", "sudo incus")

default:
    @just --list

generate:
    bluebuild generate ./recipes/recipe.yml -o Containerfile

build: generate
    bluebuild build ./recipes/recipe.yml

ignition:
    {{ container_runtime }} run --rm -i --security-opt label=disable quay.io/coreos/butane:release \
      --pretty < ignition/antares.bu \
      > ignition/antares.ign

# Download and cache the current stable FCOS live ISO.
fcos-download:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    isos=("{{ antares_workdir }}"/fedora-coreos-*-live*.x86_64.iso)
    if (( ${#isos[@]} )); then
      printf 'Using %s\n' "${isos[${#isos[@]}-1]}"
      exit
    fi
    mkdir -p "{{ antares_workdir }}"
    {{ container_runtime }} run --rm --security-opt label=disable \
      -v "{{ antares_workdir }}:/data" \
      -w /data \
      quay.io/coreos/coreos-installer:release \
      download -s stable -p metal -f iso

# Build an unattended installer ISO for the current Antares Ignition.
antares-installer-iso: fcos-download ignition
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    isos=("{{ antares_workdir }}"/fedora-coreos-*-live*.x86_64.iso)
    iso=${isos[${#isos[@]}-1]}
    ignition_hash=$(sha256sum ignition/antares.ign)
    output="{{ antares_workdir }}/antares-installer-${ignition_hash:0:12}.iso"
    if [[ -f $output ]]; then
      printf 'Using %s\n' "$output"
      exit
    fi
    {{ container_runtime }} run --rm --security-opt label=disable \
      -v "{{ antares_workdir }}:/data" \
      -v "$PWD/ignition:/ignition:ro" \
      quay.io/coreos/coreos-installer:release \
      iso customize \
        --dest-device /dev/sda \
        --dest-ignition /ignition/antares.ign \
        --dest-console ttyS0,115200n8 \
        --dest-console tty0 \
        --post-install /ignition/poweroff-after-install \
        -o "/data/${output##*/}" \
        "/data/${iso##*/}"

# Create and boot a disposable Incus VM from the FCOS live ISO.
antares-vm-create: antares-installer-iso
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    if {{ incus }} info "{{ antares_instance }}" >/dev/null 2>&1; then
      printf '%s already exists; run `just antares-vm-delete` first.\n' "{{ antares_instance }}" >&2
      exit 1
    fi
    ignition_hash=$(sha256sum ignition/antares.ign)
    iso="{{ antares_workdir }}/antares-installer-${ignition_hash:0:12}.iso"
    {{ incus }} init "{{ antares_instance }}" \
      --empty \
      --vm \
      -c limits.cpu="{{ antares_cpus }}" \
      -c limits.memory="{{ antares_memory }}" \
      -c security.secureboot=false \
      -d root,size="{{ antares_disk_size }}"
    {{ incus }} config device add "{{ antares_instance }}" install disk \
      source="$iso" \
      boot.priority=10
    {{ incus }} start "{{ antares_instance }}"

# Install Antares onto the disposable VM's system disk.
antares-vm-install:
    #!/usr/bin/env bash
    set -euo pipefail
    installed=false
    deadline=$((SECONDS + 900))
    while ((SECONDS < deadline)); do
      if [[ $({{ incus }} list "{{ antares_instance }}" -c s --format csv) == STOPPED ]]; then
        installed=true
        break
      fi
      sleep 5
    done
    if [[ $installed != true ]]; then
      printf 'Antares installer did not power off %s.\n' "{{ antares_instance }}" >&2
      exit 1
    fi
    {{ incus }} config device remove "{{ antares_instance }}" install
    {{ incus }} start "{{ antares_instance }}"

# Wait through the rebases until chezmoi setup finishes.
antares-vm-wait:
    #!/usr/bin/env bash
    set -euo pipefail
    complete=false
    deadline=$((SECONDS + {{ antares_timeout }}))
    while ((SECONDS < deadline)); do
      if {{ incus }} exec "{{ antares_instance }}" -- \
        test -e /etc/fedora-workstation-autorebase/chezmoi >/dev/null 2>&1; then
        complete=true
        break
      fi
      sleep 5
    done
    if [[ $complete != true ]]; then
      printf 'Antares bootstrap did not complete in %s.\n' "{{ antares_instance }}" >&2
      exit 1
    fi

# Verify and display the completed Antares installation.
antares-vm-status:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ incus }} exec "{{ antares_instance }}" -- sh -ceu '
      rpm-ostree status --booted | grep -Fq "ostree-image-signed:docker://ghcr.io/xtruder/fedora-workstation:latest"
      rpm-ostree status --booted
      test "$(id -u offlinehq)" -eq 1000
      ! getent passwd core
      getent passwd offlinehq
      systemctl is-active gdm.service incus-agent.service
      loginctl list-sessions --no-legend
      findmnt /boot
      findmnt /boot/efi
      ls -la /etc/fedora-workstation-autorebase
      systemctl --failed --no-pager
    '

# Connect to the Antares serial console.
antares-vm-console:
    {{ incus }} console "{{ antares_instance }}"

# Delete the disposable Antares VM if it exists.
antares-vm-delete:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! {{ incus }} info "{{ antares_instance }}" >/dev/null 2>&1; then
      exit
    fi
    {{ incus }} stop "{{ antares_instance }}" --force >/dev/null 2>&1 || true
    {{ incus }} delete "{{ antares_instance }}"

# Recreate, install, wait for, and verify the complete Antares VM.
antares-vm-test:
    just antares-vm-delete
    just antares-vm-create
    just antares-vm-install
    just antares-vm-wait
    just antares-vm-status
