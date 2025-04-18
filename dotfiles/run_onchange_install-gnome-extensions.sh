#!/usr/bin/env bash

set -euxo pipefail

# Install gnome extensions
extensions=(
    # System monitor, this is a fork of gnome-shell-extension-system-monitor
    "system-monitor-next@paradoxxx.zero.gmail.com"
    #"appindicatorsupport@rgcjonas.gmail.com"

    # Most awesome workspace switcher
    "space-bar@luchrioh"

    # Enables switching between light and dark themes using keybinding or based on system theme
    "nightthemeswitcher@romainvigier.fr"

    # For gtk3 based apps like firefox gnome will not automatically switch to dark mode
    # so we need to install this extension to switch to dark mode when firefox is in dark mode
    "legacyschemeautoswitcher@joshimukul29.gmail.com"
)

for name in "${extensions[@]}"; do
    # Get latest version from extensions.gnome.org
    version=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$name" | \
        jq -r '.shell_version_map | to_entries | max_by(.key) | .value.version')
    url="https://extensions.gnome.org/extension-data/${name//@/}.v${version}.shell-extension.zip"

    gnome-extensions install --force "$url"
done
