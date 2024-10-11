image_name := "ghcr.io/offlinehacker/fedora-workstation:latest"
bin_dir := "~/.local/bin"
current_dir := justfile_directory()

# This recipe runs before all other recipes
_: _check-path
    @just --list

build-image:
    podman build -t {{image_name}} .

# Install Chezmoi if it's not already installed
chezmoi-install: _ensure-local-bin
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v chezmoi &> /dev/null; then
        echo "Chezmoi not found. Installing..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b {{ bin_dir }}
    fi

# Initializes chezmoi config
chezmoi-init: chezmoi-install
    chezmoi init --apply --verbose "--source={{ current_dir }}/dotfiles"

install-tuxedo:
    sudo rpm-ostree install --idempotent tuxedo-control-center tuxedo-drivers
    sudo mkdir -p /etc/xdg/autostart
    sudo ln -fs /usr/etc/skel/.config/autostart/tuxedo-control-center-tray.desktop \
        /etc/xdg/autostart/tuxedo-control-center-tray.desktop

    sudo systemctl mask power-profiles-daemon.service

# Builds and installs akmods-keys package with current akmod keys
akmods-keys:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! rpm -q akmods-keys &>/dev/null; then
        cd {{ current_dir }}/silverblue-akmods-keys
        sudo bash setup.sh
        sudo rpm-ostree install akmods-keys-0.0.2-8.fc$(rpm -E %fedora).noarch.rpm
    fi

# Ensure ~/.local/bin exists
@_ensure-local-bin:
    mkdir -p ~/.local/bin

_check-path:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! echo "$PATH" | tr ':' '\n' | grep -q "$HOME/.local/bin"; then
        echo "Warning: ~/.local/bin is not in PATH" >&2
        echo "Plese add the following line to your shell configuration file (.bashrc, .zshrc, etc.):" >&2
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
        exit 1
    fi
