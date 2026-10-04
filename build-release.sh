#!/bin/sh
set -eu
cd "$(dirname "$0")"
VERSION=${1:-v0.1.0}
case "$VERSION" in
    v[0-9]*) ;;
    *) echo "Use a version such as v0.1.0." >&2; exit 1 ;;
esac
case "$VERSION" in
    *[!a-zA-Z0-9._-]*) echo "Invalid version." >&2; exit 1 ;;
esac
PACKAGE="bigstack-$VERSION-macos"
OUT="$PWD/dist/$PACKAGE"
mkdir -p "$OUT/bigstack"
clang -arch arm64 -arch x86_64 -dynamiclib -O2 \
    -mmacosx-version-min=11.0 -o "$OUT/bigstack/libbigstack.dylib" bigstack.c
codesign --force --sign - "$OUT/bigstack/libbigstack.dylib"
cp run-stellaris.sh "$OUT/bigstack/"
cp INSTALL.command "$OUT/"
cp START-HERE.txt README.md "$OUT/"
cp LICENSE "$OUT/"
chmod +x "$OUT/INSTALL.command" "$OUT/bigstack/run-stellaris.sh"
ditto -c -k --keepParent "$OUT" "$PWD/dist/$PACKAGE.zip"
shasum -a 256 "dist/$PACKAGE.zip" > "dist/$PACKAGE.zip.sha256"
printf 'Built %s\n' "dist/$PACKAGE.zip"
