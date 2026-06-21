#!/bin/bash
# Install ssext into PREFIX (default ~/.local/bin).
#   PREFIX=/usr/local/bin ./install.sh        # custom location
#   ./install.sh --enable                      # also run `on` right away
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
SRC="$(cd -P "$(dirname "$0")" && pwd)/ssext"
DST="$PREFIX/ssext"
GUI="gui/$(id -u)"

[ -f "$SRC" ] || { echo "error: $SRC not found" >&2; exit 1; }

# --- migrate from the old name (screensaver-extend), if present ---
OLD_LABEL="com.local.screensaver-extend"
if launchctl print "$GUI/$OLD_LABEL" >/dev/null 2>&1; then
    echo "migrating: unloading old $OLD_LABEL"
    launchctl bootout "$GUI/$OLD_LABEL" 2>/dev/null || true
fi
rm -f "$HOME/Library/LaunchAgents/$OLD_LABEL.plist"
rm -f "$PREFIX/screensaver-extend"
# carry over an existing config, then drop the old files
if [ -f "$HOME/.config/screensaver-extend.conf" ] && [ ! -f "$HOME/.config/ssext.conf" ]; then
    cp "$HOME/.config/screensaver-extend.conf" "$HOME/.config/ssext.conf"
fi
rm -f "$HOME/.config/screensaver-extend.conf"
rm -rf "$HOME/.local/state/screensaver-extend"

mkdir -p "$PREFIX"
install -m 0755 "$SRC" "$DST"
echo "installed -> $DST"

case ":$PATH:" in
    *":$PREFIX:"*) ;;
    *) echo "note: $PREFIX is not on your PATH. Add to ~/.zshrc:"
       echo "      export PATH=\"$PREFIX:\$PATH\"";;
esac

if [ "${1:-}" = "--enable" ]; then
    "$DST" on
else
    echo "next: ssext on        # start now + auto-start at login (default 30 min)"
    echo "      ssext set 45     # change the timeout"
fi
