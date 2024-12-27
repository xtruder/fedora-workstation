#! /usr/bin/env bash

set -euxo pipefail

DOWNLOAD_URL="https://downloader.cursor.sh/linux/appImage/x64"

# downloads cursor appimage if it doesn't exist yet
mkdir -p ~/.local/share/libexec
curl -Lo ~/.local/share/libexec/cursor.AppImage "$DOWNLOAD_URL"
chmod +x ~/.local/share/libexec/cursor.AppImage
