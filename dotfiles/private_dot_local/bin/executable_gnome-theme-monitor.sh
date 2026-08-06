#!/usr/bin/env bash
set -euo pipefail

THEME="Adwaita"

write_ini() {
    local prefer_dark="$1"
    printf '[Settings]\ngtk-theme-name=%s\ngtk-application-prefer-dark-theme=%s\n' \
        "$THEME" "$prefer_dark" > "$HOME/.config/gtk-3.0/settings.ini"
    printf '[Settings]\ngtk-theme-name=%s\ngtk-application-prefer-dark-theme=%s\n' \
        "$THEME" "$prefer_dark" > "$HOME/.config/gtk-4.0/settings.ini"
}

set_dark() {
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME"
    #write_ini 1
}

set_light() {
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME"
    #write_ini 0
}

case "$(gsettings get org.gnome.desktop.interface color-scheme)" in
    *dark*) set_dark ;;
    *)      set_light ;;
esac

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    case "$line" in
        *dark*) set_dark ;;
        *)      set_light ;;
    esac
done
