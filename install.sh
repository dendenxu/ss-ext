#!/bin/bash
# Install screensaver-extend into PREFIX (default ~/.local/bin).
#   PREFIX=/usr/local/bin ./install.sh        # custom location
#   ./install.sh --enable                      # also run `on` right away
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
SRC="$(cd -P "$(dirname "$0")" && pwd)/screensaver-extend"
DST="$PREFIX/screensaver-extend"

[ -f "$SRC" ] || { echo "error: $SRC not found" >&2; exit 1; }

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
    echo "next: $DST on        # start now + auto-start at login (default 30 min)"
    echo "      $DST set 45     # change the timeout"
fi
