antares_instance := env_var_or_default("ANTARES_INSTANCE", "antares-e2e")
antares_workdir := env_var_or_default("ANTARES_WORKDIR", "/tmp/antares-e2e")
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
    docker run --rm -i quay.io/coreos/butane:release \
      --strict --pretty < ignition/antares.bu \
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
    docker run --rm \
      -v "{{ antares_workdir }}:/data" \
      -w /data \
      quay.io/coreos/coreos-installer:release \
      download -s stable -p metal -f iso

# Create and boot a disposable Incus VM from the FCOS live ISO.
antares-vm-create: fcos-download ignition
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    if {{ incus }} info "{{ antares_instance }}" >/dev/null 2>&1; then
      printf '%s already exists; run `just antares-vm-delete` first.\n' "{{ antares_instance }}" >&2
      exit 1
    fi
    isos=("{{ antares_workdir }}"/fedora-coreos-*-live*.x86_64.iso)
    iso=${isos[${#isos[@]}-1]}
    {{ incus }} init "{{ antares_instance }}" \
      --empty \
      --vm \
      -c limits.cpu="{{ antares_cpus }}" \
      -c limits.memory="{{ antares_memory }}" \
      -c security.secureboot=false \
      -d root,size="{{ antares_disk_size }}"
    {{ incus }} config device add "{{ antares_instance }}" rescue disk \
      source="$iso" \
      boot.priority=10
    {{ incus }} start "{{ antares_instance }}"

# Install Antares onto the disposable VM's system disk.
antares-vm-install: antares-vm-create
    #!/usr/bin/env bash
    set -euo pipefail
    ready=false
    for ((attempt = 1; attempt <= 120; attempt++)); do
      if {{ incus }} exec "{{ antares_instance }}" -- true >/dev/null 2>&1; then
        ready=true
        break
      fi
      sleep 2
    done
    if [[ $ready != true ]]; then
      printf 'Incus agent did not become ready in %s.\n' "{{ antares_instance }}" >&2
      exit 1
    fi
    {{ incus }} file push ignition/antares.ign "{{ antares_instance }}/tmp/antares.ign"
    {{ incus }} exec "{{ antares_instance }}" -- \
      coreos-installer install \
        --offline \
        --ignition-file /tmp/antares.ign \
        --console ttyS0,115200n8 \
        --console tty0 \
        /dev/sda
    {{ incus }} stop "{{ antares_instance }}" --force
    {{ incus }} config device remove "{{ antares_instance }}" rescue
    {{ incus }} start "{{ antares_instance }}"

# Wait through the rebases until chezmoi and RDP setup finish.
antares-vm-wait:
    #!/usr/bin/env bash
    set -euo pipefail
    complete=false
    deadline=$((SECONDS + {{ antares_timeout }}))
    while ((SECONDS < deadline)); do
      if {{ incus }} exec "{{ antares_instance }}" -- \
        test -e /etc/fedora-workstation-autorebase/chezmoi \
             -a -e /etc/fedora-workstation-autorebase/rdp >/dev/null 2>&1; then
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
    {{ incus }} exec "{{ antares_instance }}" -- sh -c '
      uid=$(id -u offlinehq)
      rpm-ostree status --booted | grep -Fq "ostree-image-signed:docker://ghcr.io/xtruder/fedora-workstation:latest"
      rpm-ostree status --booted
      systemctl is-active gdm.service incus-agent.service
      runuser -u offlinehq -- env \
        HOME=/home/offlinehq \
        XDG_RUNTIME_DIR=/run/user/$uid \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus \
        systemctl --user is-active gnome-remote-desktop.service
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
    just antares-vm-install
    just antares-vm-wait
    just antares-vm-status
