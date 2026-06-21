#!/bin/bash
# Remove ssext: unload the agent and delete the binary, plist, config and state.
# Reverts to the MDM-enforced screensaver timeout.
set -uo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
GUI="gui/$(id -u)"

# Clean up both the current name and the legacy one, to be safe.
for name in ssext screensaver-extend; do
    label="com.local.$name"
    bin="$PREFIX/$name"
    [ -x "$bin" ] && "$bin" off 2>/dev/null || launchctl bootout "$GUI/$label" 2>/dev/null || true
    rm -f "$bin"
    rm -f "$HOME/Library/LaunchAgents/$label.plist"
    rm -f "$HOME/.config/$name.conf"
    rm -rf "$HOME/.local/state/$name"
done

echo "uninstalled — reverted to the MDM-enforced screensaver timeout."
