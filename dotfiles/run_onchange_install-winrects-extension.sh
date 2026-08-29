#!/usr/bin/env bash
set -euo pipefail

# Install the cua WinRects GNOME Shell extension (window screen geometry +
# agent cursor on GNOME Mutter Wayland). The extension files ship inside the
# cua-driver release tarball under wayland-helper/. Without it, cua-driver on
# GNOME Wayland has no window screen coordinates and captures hang.
#
# Hash inputs: the bundled extension files + this script.
# shellcheck disable=SC2312
echo "winrects hash: $(cat \
    "$HOME"/.cua-driver/packages/current/wayland-helper/winrects@cua/metadata.json \
    "$HOME"/.cua-driver/packages/current/wayland-helper/winrects@cua/extension.js \
    "$0" | sha256sum)"

src_dir="$HOME/.cua-driver/packages/current/wayland-helper/winrects@cua"
dest_dir="$HOME/.local/share/gnome-shell/extensions/winrects@cua"

if [[ ! -d "$src_dir" ]]; then
    echo "cua-driver wayland-helper not found at $src_dir — skipping WinRects install" >&2
    exit 0
fi

mkdir -p "$dest_dir"
cp -f "$src_dir/metadata.json" "$src_dir/extension.js" "$dest_dir/"

# Add to the enabled set (preserves existing entries).
cur=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "@as []")
python3 - "$cur" "winrects@cua" <<'PY'
import ast
import subprocess
import sys

cur, uuid = sys.argv[1], sys.argv[2]
try:
    enabled = ast.literal_eval(cur)
except Exception:
    enabled = []
if not isinstance(enabled, list):
    enabled = []
if uuid not in enabled:
    enabled.append(uuid)
subprocess.run(
    ["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(enabled)],
    check=True,
)
print("enabled-extensions ->", enabled)
PY

echo "Installed winrects@cua to $dest_dir."
echo "NOTE: GNOME Shell loads extensions only at session start; if the state"
echo "changed, log out/in once (or restart the session) to activate it."
