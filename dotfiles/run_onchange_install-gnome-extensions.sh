#!/usr/bin/env bash

set -euxo pipefail

# Install gnome extensions
extensions=(
    "system-monitor-next@paradoxxx.zero.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "space-bar@luchrioh"
    "nightthemeswitcher@romainvigier.fr"
)

for name in "${extensions[@]}"; do
    # Get latest version from extensions.gnome.org
    version=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$name" | \
        jq -r '.shell_version_map | to_entries | max_by(.key) | .value.version')
    url="https://extensions.gnome.org/extension-data/${name//@/}.v${version}.shell-extension.zip"

    gnome-extensions install --force "$url"
done
