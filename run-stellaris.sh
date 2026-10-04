#!/bin/sh
# Steam launch options:  "<path to this script>" %command%
# Starts Stellaris directly (skipping the Paradox Launcher; mods come from dlc_load.json)
# with libbigstack preloaded so worker threads get big stacks.
# Find the game next to this script, including in custom Steam libraries.
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
G=$(dirname -- "$HERE")
GAME="$G/stellaris.app/Contents/MacOS/stellaris"
if [ ! -f "$HERE/libbigstack.dylib" ] || [ ! -x "$GAME" ]; then
    echo "Bigstack could not find Stellaris or its fix. Run the installer again." >&2
    exit 1
fi
mkdir -p "$HOME/Library/Logs" || exit 1
export DYLD_INSERT_LIBRARIES="$HERE/libbigstack.dylib${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"
export BIGSTACK_MB="${BIGSTACK_MB:-64}"
export BIGSTACK_LOG="$HOME/Library/Logs/stellaris-bigstack.log"
echo "=== $(date) launch: $*" >> "$BIGSTACK_LOG"
cd "$G" || exit 1
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ]; then
    exec arch -arm64 -e DYLD_INSERT_LIBRARIES="$DYLD_INSERT_LIBRARIES" "$GAME" -gdpr-compliant
else
    exec "$GAME" -gdpr-compliant
fi
