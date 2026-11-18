#!/usr/bin/env bash
# Packs a Magisk module that installs Ferret as a privileged system app.
#
#   magisk/build.sh path/to/app-release.apk [--version 0.1.0] [--version-code 1] [--out file.zip]
#
# The APK should be a signed release build that includes the phone's CPU type
# (a universal APK works). The result lands in magisk/dist/ unless --out says
# otherwise.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE="io.sofluffy.ferret"

usage() {
  sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 64
}

apk=""
version=""
version_code=""
out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version="${2:-}"; shift 2 ;;
    --version-code) version_code="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *) apk="$1"; shift ;;
  esac
done

[ -n "$apk" ] || usage
[ -f "$apk" ] || { echo "No such APK: $apk" >&2; exit 66; }
command -v zip >/dev/null || { echo "zip is needed." >&2; exit 69; }
command -v unzip >/dev/null || { echo "unzip is needed." >&2; exit 69; }

unzip -l "$apk" AndroidManifest.xml >/dev/null 2>&1 ||
  { echo "Not an APK (no AndroidManifest.xml inside): $apk" >&2; exit 65; }
unzip -l "$apk" 'lib/*' >/dev/null 2>&1 ||
  { echo "This APK has no native libraries; build it with 'flutter build apk --release'." >&2; exit 65; }

# With aapt2 around, read the real package and version; otherwise trust the
# options.
aapt="$(command -v aapt2 || true)"
if [ -z "$aapt" ] && [ -n "${ANDROID_HOME:-}" ]; then
  aapt="$(find "$ANDROID_HOME/build-tools" -name aapt2 -type f 2>/dev/null | sort | tail -1)"
fi
if [ -n "$aapt" ]; then
  # sed, not head: it reads to the end, so aapt2 never dies on a closed pipe.
  badging="$("$aapt" dump badging "$apk" 2>/dev/null | sed -n '1p')"
  found_package="$(sed -n "s/.*package: name='\([^']*\)'.*/\1/p" <<<"$badging")"
  if [ "$found_package" != "$PACKAGE" ]; then
    echo "This APK is '$found_package', not '$PACKAGE'. The permissions file would not match it." >&2
    exit 65
  fi
  [ -n "$version" ] || version="$(sed -n "s/.*versionName='\([^']*\)'.*/\1/p" <<<"$badging")"
  [ -n "$version_code" ] || version_code="$(sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" <<<"$badging")"
else
  echo "aapt2 not found: the APK's package name was not checked." >&2
fi

[ -n "$version" ] || { echo "Pass --version (aapt2 could not read it)." >&2; exit 64; }
[ -n "$version_code" ] || { echo "Pass --version-code (aapt2 could not read it)." >&2; exit 64; }
[[ "$version" =~ ^[0-9A-Za-z.+_-]+$ ]] || { echo "Odd version: $version" >&2; exit 64; }
[[ "$version_code" =~ ^[0-9]+$ ]] || { echo "The version code must be a number: $version_code" >&2; exit 64; }

[ -n "$out" ] || out="$HERE/dist/ferret-magisk-v$version.zip"
mkdir -p "$(dirname "$out")"
out="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

work="$(mktemp -d)"
trap 'rm -r -- "$work"' EXIT

cp -R "$HERE/template/." "$work/"
rm -f "$work/system/priv-app/Ferret/README.txt"
cp "$apk" "$work/system/priv-app/Ferret/Ferret.apk"
sed -e "s/@VERSION@/v$version/" -e "s/@VERSION_CODE@/$version_code/" \
  "$HERE/template/module.prop" > "$work/module.prop"

rm -f "$out"
# The APK is compressed already; storing it keeps the build fast.
(cd "$work" && zip -q -r -X -n .apk "$out" .)

echo "Built $out"
echo "Untested on real devices. Read magisk/README.md before flashing."
