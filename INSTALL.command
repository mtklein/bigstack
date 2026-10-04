#!/bin/sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
G="$HOME/Library/Application Support/Steam/steamapps/common/Stellaris"

fail() {
    printf '\nSetup did not finish: %s\n' "$1" >&2
    exit 1
}

[ -f "$HERE/bigstack/libbigstack.dylib" ] || fail "Download and unzip the release ZIP first."
[ -f "$HERE/bigstack/run-stellaris.sh" ] || fail "The download is missing its launch script."

printf 'Installing the Stellaris bigstack fix…\n'
if [ ! -x "$G/stellaris.app/Contents/MacOS/stellaris" ]; then
    printf 'Select the Stellaris folder. In Steam, right-click Stellaris, then Manage > Browse local files.\n'
    G=$(osascript -e 'POSIX path of (choose folder with prompt "Choose the Stellaris folder that Steam opens with Manage > Browse local files.")') || fail "No game folder was selected. You can run setup again."
    G=${G%/}
fi
[ -x "$G/stellaris.app/Contents/MacOS/stellaris" ] || fail "That folder does not contain Stellaris. Select the folder containing stellaris.app."

mkdir -p "$G/bigstack"
cp "$HERE/bigstack/libbigstack.dylib" "$HERE/bigstack/run-stellaris.sh" "$G/bigstack/"
chmod +x "$G/bigstack/run-stellaris.sh"
# Only remove the download marker from the two files the user chose to install.
xattr -d com.apple.quarantine "$G/bigstack/libbigstack.dylib" 2>/dev/null || :
xattr -d com.apple.quarantine "$G/bigstack/run-stellaris.sh" 2>/dev/null || :

# Protect paths containing shell-sensitive characters in Steam's launch setting.
ESCAPED=$(printf '%s' "$G/bigstack/run-stellaris.sh" | sed 's/[\\"$`]/\\&/g')
OPTIONS=$(printf '"%s" %%command%%' "$ESCAPED")
printf '%s' "$OPTIONS" | pbcopy
printf '\nThe fix is installed, and your Steam setting is copied.\n\n'
printf '1. In Steam, right-click Stellaris and choose Properties.\n'
printf '2. Under General, click Launch Options.\n'
printf '3. Replace anything in that box by pressing Command-V.\n'
printf '4. Close Properties and click Play.\n\n'
printf 'If you need to copy the setting again, it is:\n%s\n\n' "$OPTIONS"
printf 'You can close this Terminal window now.\n'
