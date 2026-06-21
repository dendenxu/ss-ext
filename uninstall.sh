#!/bin/bash
# Remove screensaver-extend: unload the agent and delete the binary, plist,
# config and state. Reverts to the MDM-enforced screensaver timeout.
set -uo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
DST="$PREFIX/screensaver-extend"
LABEL="com.local.screensaver-extend"

[ -x "$DST" ] && "$DST" off || launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

rm -f "$DST"
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -f "$HOME/.config/screensaver-extend.conf"
rm -rf "$HOME/.local/state/screensaver-extend"

echo "uninstalled — reverted to the MDM-enforced screensaver timeout."
