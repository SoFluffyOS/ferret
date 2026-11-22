#!/usr/bin/env bash
# Builds the Android APK for a GitHub release:
#
#   build/android-packages/Ferret-<version>.apk
#   build/android-packages/Ferret-android.apk   (same file; the landing page's
#                                                Download button points here:
#                                                releases/latest/download/…)
#
# Needs the release key in apps/ferret/android/key.properties (storeFile,
# storePassword, keyAlias, keyPassword). Every release must use the same key,
# or Android won't install it over the one before. FERRET_ALLOW_DEBUG_KEY=1
# builds with the debug key anyway, for testing only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/ferret"
OUT="$ROOT/build/android-packages"

version="$(sed -n 's/^version: *\([^+]*\).*/\1/p' "$APP/pubspec.yaml")"
[ -n "$version" ] || { echo "No version in $APP/pubspec.yaml" >&2; exit 1; }

if [ ! -f "$APP/android/key.properties" ] && [ "${FERRET_ALLOW_DEBUG_KEY:-}" != "1" ]; then
  cat >&2 <<EOF
No release key: apps/ferret/android/key.properties is missing.
A public APK has to be signed with the same key forever. Create one with
  keytool -genkey -v -keystore ~/ferret-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias ferret
then write key.properties (see https://docs.flutter.dev/deployment/android#signing-the-app).
FERRET_ALLOW_DEBUG_KEY=1 builds a test APK with the debug key.
EOF
  exit 1
fi

echo "==> APK $version"
(cd "$APP" && fvm flutter build apk --release)

mkdir -p "$OUT"
cp -f "$APP/build/app/outputs/flutter-apk/app-release.apk" "$OUT/Ferret-$version.apk"
cp -f "$OUT/Ferret-$version.apk" "$OUT/Ferret-android.apk"

# Ferret's updater refuses a download whose SHA-256 isn't in the release's
# SHA256SUMS. Merge this file with the other platforms' into the one
# SHA256SUMS the release carries.
(cd "$OUT" && shasum -a 256 "Ferret-$version.apk" Ferret-android.apk >SHA256SUMS)

echo
echo "Done:"
cat "$OUT/SHA256SUMS"
