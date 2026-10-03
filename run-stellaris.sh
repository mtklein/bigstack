#!/bin/sh
# Steam launch options:  "<path to this script>" %command%
# Starts Stellaris directly (skipping the Paradox Launcher; mods come from dlc_load.json)
# with libbigstack preloaded so worker threads get big stacks.
G="$HOME/Library/Application Support/Steam/steamapps/common/Stellaris"
export DYLD_INSERT_LIBRARIES="$G/bigstack/libbigstack.dylib${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"
export BIGSTACK_MB="${BIGSTACK_MB:-64}"
export BIGSTACK_LOG="$HOME/Library/Logs/stellaris-bigstack.log"
echo "=== $(date) launch: $*" >> "$BIGSTACK_LOG"
cd "$G" && exec arch -arm64 -e DYLD_INSERT_LIBRARIES="$DYLD_INSERT_LIBRARIES" ./stellaris.app/Contents/MacOS/stellaris -gdpr-compliant
