#!/usr/bin/env bash

set -euxo pipefail

# Install gnome extensions
declare -A extensions=(
    ["system-monitor-next@paradoxxx.zero.gmail.com"]="75"
    ["appindicatorsupport@rgcjonas.gmail.com"]="59"
    ["space-bar@luchrioh"]="32"
    ["nightthemeswitcher@romainvigier.fr"]="78"
)

for name in "${!extensions[@]}"; do
    # Skip if extension is already installed
    if gnome-extensions info "$name" &>/dev/null; then
        echo "Extension $name is already installed"
        continue
    fi

    version="${extensions[$name]}"
    url="https://extensions.gnome.org/extension-data/${name//@/}.v${version}.shell-extension.zip"
    gnome-extensions install "$url"
done
