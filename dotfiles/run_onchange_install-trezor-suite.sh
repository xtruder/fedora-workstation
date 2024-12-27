#! /usr/bin/env bash

set -euxo pipefail

DOWNLOAD_URL="https://data.trezor.io/suite/releases/desktop/latest/Trezor-Suite-24.11.3-linux-x86_64.AppImage"

# downloads trezor-suite appimage if it doesn't exist yet
mkdir -p ~/.local/share/libexec
curl -Lo ~/.local/share/libexec/trezor-suite.AppImage "$DOWNLOAD_URL"
chmod +x ~/.local/share/libexec/trezor-suite.AppImage
