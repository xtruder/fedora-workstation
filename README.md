# fedora-workstation

A personal, immutable Fedora Silverblue desktop image built with
[BlueBuild](https://blue-build.org). It layers a curated set of packages,
system configuration, dotfiles, and post-install tooling on top of
[`ublue-os/silverblue-main`](https://github.com/ublue-os/silverblue) and
ships as a signed OCI image to ghcr.io, ready to rebase onto with
`rpm-ostree`.

The image targets Framework-style laptops (with AMD ROCm support) running
GNOME on Wayland, and bundles everything from virtualization (incus,
libvirt, podman) to security tooling (usbguard, yubikey, tor), Framework
hardware utilities (fw-fanctrl, fw-ectool), and developer tools.

## Table of contents

- [How it's built](#how-its-built)
- [Repository layout](#repository-layout)
- [Building locally](#building-locally)
- [Incus VM bootstrap](#incus-vm-bootstrap)
- [Installing](#installing)
  - [From an ISO](#from-an-iso)
  - [Rebasing an existing Silverblue install](#rebasing-an-existing-silverblue-install)
  - [Switching to signed images](#switching-to-signed-images)
- [Dotfiles](#dotfiles)
- [Post-install setup](#post-install-setup)
  - [Firmware updates](#firmware-updates)
  - [Power management](#power-management)
  - [Firmware / TPM](#firmware--tpm)
  - [Fingerprint reader](#fingerprint-reader)
  - [USB device authorization](#usb-device-authorization)
  - [Thunderbolt](#thunderbolt)
  - [SSH server](#ssh-server)
  - [GPG keys](#gpg-keys)
  - [Incus](#incus)
  - [1Password](#1password)
  - [Nextcloud sync](#nextcloud-sync)
  - [Firefox](#firefox)
- [Included `ujust` commands](#included-ujust-commands)
- [CI](#ci)
- [Notes](#notes)

## How it's built

The source of truth is [`recipes/recipe.yml`](recipes/recipe.yml), a
[BlueBuild recipe](https://blue-build.org/reference/recipe/). The
`Containerfile` in the root is **generated** from the recipe and is
git-ignored — do not edit it directly.

The recipe runs these modules in order:

| Module              | Purpose                                                                                  |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `files`             | Copies `files/system/*` into the image root (`/etc/...` config overlay)                  |
| `script`            | Prunes orphaned kernel module trees left over from base image upgrades                   |
| `rpm-ostree`        | Installs the main package set (see below) and removes stock Firefox                      |
| `bling`             | Installs 1Password and a dconf-update service                                            |
| `default-flatpaks`  | Installs `org.mozilla.firefox`, `org.gnome.Loupe`; removes `org.gnome.eog`               |
| `systemd`           | Enables usbguard, incus, powertop, tailscaled, tpm-hibernate-reset; disables flatpak timer |
| `justfiles`         | Ships user-runnable `ujust` commands (see [below](#included-ujust-commands))             |
| `script`            | Appends the `tss` group, fixes usbguard IPC ACL permissions                              |
| `brew`              | Installs Homebrew (analytics off, raised nofile limits, direct-pull to avoid GH API caps)|
| `chezmoi`           | Wires up dotfiles from this repo (users opt in via `ujust dotfiles`)                     |
| `signing`           | Installs ostree signing policy using `cosign.pub`                                        |

### Package highlights

The `rpm-ostree` module installs (grouped by purpose):

- **System / dev**: `htop`, `vim-common`, `ncdu`, `unrar`, `unzip`, `p7zip`,
  `procps`, `strace`, `bcc`, `zenity`, `make`, `gcc`, `python3-devel`,
  `python3-pip`, `python3-tkinter`, `python-systemd`, `gnupg2`,
  `rpmdevtools`, `smartmontools`, `acpica-tools`
- **Kernel modules**: `akmods`, plus third-party repos (Tuxedo, bazzite,
  ublue-os-akmods/staging, ghostty, nordvpn, vscode, cursor, windsurf,
  open-code)
- **Power / hardware**: `powertop`, `fw-fanctrl`, `fw-ectool`, `ryzenadj`
- **GUI / GNOME**: `gnome-tweak-tool`, `ulauncher`,
  `gnome-shell-extension-pop-shell`, `gnome-shell-extension-appindicator`,
  `simple-scan`, `ghostty`
- **Networking / VPN**: `tailscale`, `wireguard-tools`, `NetworkManager-l2tp`
- **Virtualization / containers**: `incus`, `qemu-kvm`, `qemu-img`,
  `libvirt-daemon-kvm`, `virt-manager`, `virt-install`, `virt-top`,
  `virt-viewer`, `podman`, `podman-compose`, `containernetworking-plugins`,
  `waydroid`, `edk2-ovmf`, `edk2-aarch64`
- **Security / crypto**: `usbguard`, `usbguard-dbus`, `pcsc-tools`,
  `libykneomgr`, `pam_yubico`, `nyx`, `tor`, `aircrack-ng`, `nmap`,
  `wireshark-cli`, `pass`, `qtpass`
- **AMD ROCm**: `rocminfo`, `rocm-smi`
- **Android / USB**: `android-tools`, `libusb1-devel`, `libudev-devel`
- **Bench**: `stress-ng`, `s-tui`
- **Editors**: `code` (VSCode / VSCodium); settings sync via `zokugun.sync-settings`
- **Filesystem / encryption**: `fscrypt`, `davfs2`, `sirikali`

Removed: `firefox`, `firefox-langpacks` (replaced by the Flatpak).

## Repository layout

```
.
├── recipes/recipe.yml     # BlueBuild recipe — the source of truth
├── files/
│   ├── system/            # Overlay copied into / (etc/ configs)
│   ├── rpm-ostree/        # Third-party .repo files
│   ├── justfiles/         # ujust commands shipped with the image
│   ├── systemd/           # (reserved for systemd unit overrides)
│   └── scripts/           # (reserved for build-time scripts)
├── dotfiles/              # chezmoi source dir (see .chezmoiroot)
├── sysext/                # system-extension definitions (drata-agent, jcagent)
├── cosign.pub             # public key for image signing verification
├── .github/workflows/     # CI builds
├── Justfile               # `just generate` / `just build`
└── Containerfile          # GENERATED — do not edit
```

### System config overlay (`files/system/etc/`)

Notable files baked into the image:

- `etc/usbguard/IPCAccessControl.d/offlinehq` — usbguard IPC ACL
- `etc/firewalld/zones/trusted.xml` — firewalld trusted zone
- `etc/NetworkManager/dispatcher.d/dnsovertls.sh` — DNS-over-TLS hook
- `etc/systemd/resolved.conf` — resolved configuration
- `etc/systemd/system/tpm-hibernate-reset.service` — resets TPM counters
  on hibernate
- `etc/sysctl.d/99-rootles-net.conf` — rootless container sysctls
- `etc/sysctl.d/99-ptrace-scope.conf` — sets `kernel.yama.ptrace_scope=1` (needed by 1Password)
- `etc/sysusers.d/99-users-groups.conf` — static user/group declarations
- `etc/udev/rules.d/hp_lt4110.rules` — HP LT4110 modem udev rule
- `etc/1password/custom_allowed_browsers` — browsers allowed to integrate
  with the 1Password desktop app

## Building locally

Requires [BlueBuild](https://blue-build.org/install/) and `just`.

```sh
# Regenerate the Containerfile from the recipe
just generate

# Build the image locally
just build
```

You can also invoke `bluebuild` directly:

```sh
bluebuild generate ./recipes/recipe.yml -o Containerfile
bluebuild build ./recipes/recipe.yml
```

## Incus VM bootstrap

[`ignition/antares.bu`](ignition/antares.bu) bootstraps
an Incus Fedora CoreOS/uCore VM using the same pattern as the homelab server.
It also configures Incus's 9p agent share and SELinux policy so `incus exec`
continues working after reboot. GNOME RDP is configured automatically with a
generated password stored in root-only
`/etc/fedora-workstation-autorebase/rdp-credentials`.

Generate strict Ignition JSON with:

```sh
just ignition
```

Run the complete disposable Incus installation test with:

```sh
just antares-vm-test
```

On its first run, this downloads a stable FCOS live ISO and caches it under
`data/`, builds an unattended installer from `ignition/antares.ign`, recreates
the `antares` VM, waits through the automatic rebases, and verifies the
finished workstation. Override the defaults with `ANTARES_INSTANCE`,
`ANTARES_WORKDIR`, `ANTARES_CPUS`, `ANTARES_MEMORY`, `ANTARES_DISK_SIZE`,
`ANTARES_TIMEOUT`, `CONTAINER_RUNTIME`, or `INCUS`. Podman is preferred when
both Podman and Docker are installed.

The full test is destructive to the configured `ANTARES_INSTANCE`. Its
individual stages are available as `fcos-download`, `antares-installer-iso`,
`antares-vm-create`, `antares-vm-install`, `antares-vm-wait`, `antares-vm-status`,
`antares-vm-console`, and `antares-vm-delete`. Set `INCUS=incus` when the
current user can access Incus without `sudo`.

The bootstrap then follows these stages:

1. Rebase from uCore to the unsigned
   `ghcr.io/xtruder/fedora-workstation:latest` deployment and reboot.
2. Rebase to the signed transport after the workstation image supplies its
   signing policy, then reboot again.
3. Enable GDM autologin, SSH, and lingering for `offlinehq`.
4. Wait for the autologged-in GNOME session, configure RDP, and apply chezmoi
   using the preseeded VM config.

Boot the VM from the official Fedora CoreOS ISO and install to its system disk
using the generated Ignition file:

```sh
sudo coreos-installer install \
  -I https://raw.githubusercontent.com/xtruder/fedora-workstation/main/ignition/antares.ign \
  /dev/sda
```

Confirm the target disk with `lsblk` before running the installer. The
autorebase state under `/etc/fedora-workstation-autorebase/` makes each stage
idempotent across the required reboots. Initial chezmoi setup does not access
1Password. Hermes service configuration is completed manually on the VM.
Nested Incus configuration is also optional; set `incus = true` only on hosts
that should receive the Incus network, storage pool, and profiles.

The Incus test deliberately boots an unmodified official FCOS live ISO, pushes
the generated Ignition into the live VM, and runs `coreos-installer install
--offline` there. The Ignition config assumes the standard FCOS `/dev/sda`
partition layout and recreates the boot and root partitions on first boot. It
expands `/boot` to 2 GiB because the workstation initramfs and the FCOS rollback
deployment do not fit in FCOS's default 384 MiB partition. Do not use
`coreos-installer iso ignition embed`: it configures the live environment but
does not install the target disk. Temporary `incus exec` failures are expected
while the VM reboots between stages. `just antares-vm-status` verifies the
signed deployment, system and RDP services, boot mounts, active session, and
state markers. The final `chezmoi` marker is created only after GDM has started
an active Wayland session.

The preseeded `fs_type` must remain `xfs` for this FCOS layout. The Incus
preseed selects a `dir` pool for non-Btrfs filesystems; setting `fs_type` to
`btrfs` on the XFS root makes Incus reject the storage pool path. If chezmoi
initialization fails, check that `~/.config` and `~/.config/systemd/user` are
owned by `offlinehq`. Patterns in `.chezmoiignore.tmpl` are root-relative;
recursive patterns use `**/pattern`, not `/**/pattern`.

## Installing

### From an ISO

```sh
sudo bluebuild generate-iso --iso-name fedora-workstation.iso image ghcr.io/xtruder/fedora-workstation:41
```

### Rebasing an existing Silverblue install

On a machine already running Fedora Silverblue:

```sh
# Unverified image (first rebase only)
sudo rpm-ostree rebase --reboot ostree-unverified-registry:ghcr.io/xtruder/fedora-workstation:latest

# Once the signing policy is in place, switch to the signed image
sudo rpm-ostree rebase --reboot ostree-image-signed:docker://ghcr.io/xtruder/fedora-workstation:latest
```

### Switching to signed images

The `signing` module installs the cosign public key (`cosign.pub`) and the
ostree signing policy, so after the first rebase you can move from the
`ostree-unverified-registry:` transport to `ostree-image-signed:` for
verified, tamper-evident updates.

## Dotfiles

Dotfiles are managed with [chezmoi](https://www.chezmoi.io) and live in
the `dotfiles/` directory (`.chezmoiroot` points chezmoi at it). The
chezmoi module in the recipe only wires up the source — you opt in on
the running system.

```sh
ujust dotfiles
```

This runs `chezmoi init --apply` against this repo (over HTTPS, prompting
for config values like name, email, filesystem type, and feature flags:
work / crypto / gaming / multimedia / hermes) and rewrites the push remote to
SSH.

To pull updates afterward:

```sh
chezmoi update
```

### What the dotfiles set up

The `run_onchange_*` scripts in `dotfiles/` run automatically when their
inputs change:

- `run_onchange_dconf-load.sh.tmpl` — loads GNOME/dconf settings from
  `dconf.ini` (keyboard layout `us` + `si+us`, dark theme, night light,
  pop-shell tiling, space-bar workspace indicator, custom keybindings for
  ulauncher and 1Password quick access, power-button = hibernate, etc.)
- `run_onchange_install_flatpaks.sh.tmpl` — installs user Flatpaks
- `run_onchange_install_python_pkgs.sh.tmpl` — installs pip packages
- `run_onchange_install-gnome-extensions.sh` — installs GNOME Shell
  extensions
- `run_onchange_install-ngrok.sh` — installs ngrok
- `run_onchange_install-opencode-appimage.sh.tmpl` — installs and updates the OpenCode AppImage
- `run_onchange_install-openchamber-appimage.sh.tmpl` — installs OpenChamber v1.18.1 from its AppImage
- `run_onchange_install-eden-appimage.sh.tmpl` — installs and updates Eden on gaming systems
- `run_onchange_install-trezor-suite.sh.tmpl` — installs Trezor Suite
- `run_onchange_incus-preseed.sh.tmpl` — applies an Incus preseed
  (`incus-preseed.yaml.tmpl`)
- `run_onchange_after_10-install-hermes.sh.tmpl` — installs the pinned Hermes Agent,
  WebUI, and Cua Driver compatibility set when `hermes = true`

## Post-install setup

### Firmware updates

```sh
fwupdmgr refresh
fwupdmgr update
```

### Power management

#### Suspend debugging

Check available suspend states and debug S0ix residency:

```sh
cat /sys/power/mem_sleep
sudo powertop
```

For deeper S0ix analysis on Intel hardware:

```sh
git clone https://github.com/intel/S0ixSelftestTool.git
cd S0ixSelftestTool
sudo ./s0ix-selftest-tool.sh -s
```

### Firmware / TPM

```sh
# TPM2 tools (explore capabilities)
sudo tpm2_getcap -l

# Add yourself to the tss group for TPM access
sudo usermod -a -G tss "$USER"
newgrp tss
```

### Fingerprint reader

Fingerprints are enrolled via GNOME Settings. To remove an enrolled
fingerprint from the CLI:

```sh
sudo fprintd-delete "$USER"
```

### USB device authorization

After first boot, `usbguard` will block peripherals. List and
permanently authorize your keyboard, mouse, and other trusted devices:

```sh
usbguard list-devices
usbguard allow-device --permanent <id>
```

### Thunderbolt

#### Bolt service

```sh
sudo systemctl start bolt
sudo boltctl list
sudo boltctl domains
```

#### Auto-authorization (IOMMU-protected)

On machines with IOMMU DMA protection, Thunderbolt devices can be
safely auto-authorized. Create a udev rule:

```sh
sudo tee /etc/udev/rules.d/99-thunderbolt-auto-authorize.rules <<'EOF'
# Auto-authorize when IOMMU DMA protection is active (safe)
ACTION=="add", SUBSYSTEM=="thunderbolt", ATTRS{iommu_dma_protection}=="1", ATTR{authorized}=="0", ATTR{authorized}="1"
EOF
sudo udevadm control --reload-rules
```

Optionally load the Thunderbolt networking module:

```sh
sudo modprobe thunderbolt-net
```

### SSH server

```sh
sudo systemctl start sshd
sudo firewall-cmd --add-port=22/tcp --zone=FedoraWorkstation
```

Set up your authorized keys:

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
vi ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### GPG keys

Search for and import a public key from keyservers:

```sh
gpg2 --search-keys <email>
```

Import a secret key file, transfer it to TPM, and trust it:

```sh
gpg2 --import <key-file>
gpg2 --edit-key <key-id>
# At the gpg> prompt, run: keytotpm -> trust -> 5 -> quit
```

To use a GPG key for SSH authentication, add its keygrip to
`~/.gnupg/sshcontrol`:

```sh
gpg2 --with-keygrip -K <key-id>
# Copy the keygrip line and add it to:
echo <keygrip> >> ~/.gnupg/sshcontrol
```

### Incus

#### Group membership

Add yourself to both the `incus` and `incus-admin` groups and refresh
your session:

```sh
grep -E '^incus-admin:' /usr/etc/group | sudo tee -a /etc/group
sudo usermod -a -G incus-admin "$USER"
sudo usermod -a -G incus "$USER"
newgrp incus-admin
```

#### Subuid/subgid mappings

```sh
sudo usermod --add-subuids 524288-65536 "$USER"
sudo usermod --add-subuids 1000000-1000000000 root
sudo usermod --add-subgids 524288-65536 "$USER"
sudo usermod --add-subgids 1000000-1000000000 root
```

#### HTTPS API (remote access)

Expose the Incus API on the LAN for use from other machines (e.g. a
Framework laptop acting as a server):

```sh
sudo incus config set local: core.https_address=:8443
sudo firewall-cmd --add-port=8443/tcp --zone=FedoraWorkstation
```

On the remote machine, add the trust token:

```sh
incus config trust add framework
# paste the token generated by `incus config trust list` on the server
```

#### Dev container

Create and start a dev container:

```sh
incus create images:ubuntu/24.04/cloud --profile ubuntu-dev ubuntu-dev
incus start ubuntu-dev
```

Mount your code directory into the container (shifted for unprivileged
UID mapping):

```sh
incus config device add ubuntu-dev code disk \
  source=/var/home/$USER/Code path=/home/$USER/Code shift=true
```

Push an SSH key so you can `ssh` in:

```sh
incus file push ~/.ssh/id_ed25519.pub \
  ubuntu-dev/home/$USER/.ssh/authorized_keys --create-dirs --mode 0600
```

Add an SSH config entry:

```sh
IP=$(incus list ubuntu-dev -f json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet").address')
cat >> ~/.ssh/config << EOF
Host ubuntu-dev
    HostName $IP
    ForwardAgent yes
    RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra
EOF
```

Connect:

```sh
incus exec ubuntu-dev -- bash   # or
ssh ubuntu-dev
```

### 1Password

The `bling` module installs 1Password. Sign in, then ensure your browser
is listed in `/etc/1password/custom_allowed_browsers` so the browser
extension can talk to the desktop app.

The optional Hermes profile requires desktop app CLI integration. Keep
`hermes = false` during initial setup, sign in to 1Password, then enable the
flag in the local chezmoi config and run `chezmoi apply`. The required item
fields and manual Traefik examples are documented in
[`examples/hermes/`](examples/hermes/).

### Nextcloud sync

The Nextcloud Desktop Flatpak is installed for the `work` profile. Configure
its account interactively after login. GNOME Online Accounts and WebDAV via
`davfs2` remain available as alternatives.

### Firefox

The rpm Firefox is removed in favor of the Flatpak. Most settings sync
once you sign into a Firefox account, but the manual steps are:

- Create Firefox profiles (e.g. Personal / Work)
- Sign in with Firefox Sync
- Configure basics:
  - Reopen windows/tabs on restart
  - Set desktop theme to auto-switch
  - Enable HTTPS-only mode
  - Enable hardware-accelerated playback with
    `media.ffmpeg.vaapi.enabled` (also sync via
    `services.sync.prefs.sync-seen.media.ffmpeg.vaapi.enabled`)
- Install extensions:
  - [multi-account-containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/)
  - Dark Reader (enable auto-switch)
  - uBlock Origin
  - 1Password
  - Window Titler
  - ClearURLs
  - Link to Text Fragment
- Create Work / Personal containers
- Sign in to sites in the appropriate profile/container: mail, YouTube,
  YouTube Music

## Included `ujust` commands

The `justfiles` module ships these commands, available on the running
system via `ujust`:

| Command             | Description                                                                          |
| ------------------- | ------------------------------------------------------------------------------------ |
| `ujust dotfiles`    | Initialize and apply chezmoi dotfiles from this repo (see [Dotfiles](#dotfiles))     |
| `ujust akmods-keys` | Build and install the `akmods-keys` package for the running Fedora version           |
| `ujust build-akmods-keys` | Build the `akmods-keys` RPM only (does not install)                            |
| `ujust install-tuxedo` | Install Tuxedo Control Center + akmod-tuxedo-drivers and wire its autostart entry |

> The `install-tuxedo` justfile is **not** included by the recipe by
> default (it's commented out in `recipes/recipe.yml`). Enable it there
> if you're running on Tuxedo hardware.

## CI

[`.github/workflows/build.yml`](.github/workflows/build.yml) runs the
`blue-build/github-action@v1.11.1` reusable action. It triggers on:

- pushes to `recipes/`, `files/`, `cosign.pub`, or the workflow itself
- pull requests
- a daily `07:00 UTC` schedule (after the upstream ublue-os images
  rebuild, typically ~06:30–06:50 UTC)
- manual `workflow_dispatch`

Builds are signed with the `SIGNING_SECRET` cosign key and pushed to
`ghcr.io/xtruder/fedora-workstation`. Only one build runs at a time per
ref (`cancel-in-progress: true`).

## Notes

- The `akmods` BlueBuild module is intentionally disabled in the recipe
  (see the comment in `recipes/recipe.yml`). An empty `install: []` makes
  the module fail; only re-enable it when you need specific kernel
  modules (e.g. `install: [openrazer, v4l2loopback]`). See
  <https://blue-build.org/reference/modules/akmods/>.
- The `Containerfile` and `.bluebuild-scripts_*` directory are
  build artifacts and are git-ignored.
- `image-version: 44` in the recipe pins the Fedora major version;
  bump it when rebasing onto a new Fedora release.
