#!/usr/bin/env bash

set -euo pipefail

URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"

echo "Downloading ngrok from $URL, installing to ~/.local/bin/ngrok"
curl --progress-bar "$URL" | tar -xz -C ~/.local/bin
chmod +x ~/.local/bin/ngrok
