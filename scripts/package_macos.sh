#!/usr/bin/env bash
# Builds Ferret's macOS release into build/macos-packages:
#
#   scripts/package_macos.sh            build, check signatures, DMG, sign it,
#                                       then notarize if FERRET_NOTARY_PROFILE is set
#   scripts/package_macos.sh notarize   notarize, staple and zip the DMG built last
#
# Runs on macOS only, with Xcode and the "Developer ID Application: Cuong Pham
# (66UZUS2MST)" certificate in the login keychain. The Release configuration
# already signs the app, its frameworks and the Share extension with it
# (hardened runtime, secure timestamp, no get-task-allow).
#
# The script adds ferret-cli (dart compile exe) to Ferret.app/Contents/Helpers,
# signs it, re-signs the app around it, and checks every nested piece.
#
# FERRET_NOTARY_PROFILE  the notarytool keychain profile to submit with
#                        (see packaging/macos/README.md to create it once)
# FERRET_SKIP_BUILD=1    reuse the last flutter build instead of building again
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PACKAGING="$ROOT/packaging/macos"
OUT="$ROOT/build/macos-packages"
# Scratch trees go to fresh temp folders, and an old stage is moved there, so
# nothing is deleted.
STAGE="$OUT/stage"
APP="$STAGE/Ferret.app"
BUILT_APP="$ROOT/apps/ferret/build/macos/Build/Products/Release/ferret.app"
TEAM="66UZUS2MST"
IDENTITY="Developer ID Application: Cuong Pham ($TEAM)"
VOLUME="Ferret"
target="${1:-build}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "package_macos.sh runs on macOS only (this is $(uname -s))." >&2
  exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
  echo "No \"$IDENTITY\" certificate in the keychain." >&2
  echo "Download it from developer.apple.com (Certificates) or Xcode > Settings > Accounts." >&2
  exit 1
fi

version="$(sed -n 's/^version: *\([^+]*\).*/\1/p' apps/ferret/pubspec.yaml)"
DMG="$OUT/Ferret-$version.dmg"
ZIP="$OUT/Ferret-$version-mac.zip"

build_app() {
  if [ "${FERRET_SKIP_BUILD:-}" = "1" ] && [ -d "$BUILT_APP" ]; then
    echo "==> Reusing the last release build ($version)"
  else
    echo "==> Flutter release build ($version)"
    (cd apps/ferret && "$ROOT/scripts/with_lock.sh" build fvm flutter build macos --release)
  fi

  if [ -d "$STAGE" ]; then
    mv "$STAGE" "$(mktemp -d)/"
  fi
  mkdir -p "$STAGE"
  # The bundle's folder name isn't part of its signature, so it can carry the
  # capitalised name people see in Applications.
  ditto "$BUILT_APP" "$APP"
}

add_cli() {
  echo "==> ferret-cli"
  local helpers="$APP/Contents/Helpers"

  mkdir -p "$helpers"
  (cd apps/ferret_cli && fvm dart compile exe bin/ferret.dart -o "$helpers/ferret-cli")
  # A Dart executable maps its own AOT snapshot as code, which the hardened
  # runtime only allows with allow-unsigned-executable-memory.
  codesign --force --options runtime --timestamp \
    --identifier io.sofluffy.ferret.cli \
    --entitlements "$PACKAGING/ferret-cli.entitlements" \
    --sign "$IDENTITY" "$helpers/ferret-cli"
  codesign --force --options runtime --timestamp \
    --preserve-metadata=identifier,entitlements,requirements,flags \
    --sign "$IDENTITY" "$APP"
}

# Fails unless the code at $1 is signed by our team with a Developer ID, a
# secure timestamp and no get-task-allow. Executables also need the hardened
# runtime; frameworks are libraries, which notarization doesn't ask it of (the
# app's runtime covers what they load into).
check_code() {
  local path="$1" kind="${2:-executable}" info entitlements

  info="$(codesign -dvv "$path" 2>&1)"
  entitlements="$(codesign -d --entitlements - --xml "$path" 2>/dev/null || true)"
  if ! grep -q "^TeamIdentifier=$TEAM$" <<<"$info"; then
    echo "Not signed by team $TEAM: $path" >&2
    return 1
  fi
  if ! grep -q "^Authority=Developer ID Application" <<<"$info"; then
    echo "Not signed with a Developer ID: $path" >&2
    return 1
  fi
  if [ "$kind" = "executable" ] && ! grep -q "flags=.*runtime" <<<"$info"; then
    echo "No hardened runtime: $path" >&2
    return 1
  fi
  if ! grep -q "^Timestamp=" <<<"$info"; then
    echo "No secure timestamp: $path" >&2
    return 1
  fi
  if grep -q "get-task-allow" <<<"$entitlements"; then
    echo "Has get-task-allow (a debug signature): $path" >&2
    return 1
  fi
  echo "    ok  ${path#"$STAGE/"}"
}

verify_app() {
  echo "==> Checking signatures"
  codesign --verify --deep --strict --verbose=2 "$APP"

  check_code "$APP"
  check_code "$APP/Contents/PlugIns/Share.appex"
  check_code "$APP/Contents/Helpers/ferret-cli"
  local framework
  for framework in "$APP"/Contents/Frameworks/*.framework; do
    check_code "$framework" library
  done
}

# Lays out the window people see when they open the DMG: the app on the left,
# Applications on the right, nothing else. Needs Finder; if macOS doesn't let
# this shell script Finder, the DMG still works with Finder's default layout.
style_window() {
  local script

  script="$(cat <<EOF
tell application "Finder"
  tell disk "$VOLUME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 740, 460}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 13
    set position of item "Ferret.app" of container window to {140, 150}
    set position of item "Applications" of container window to {400, 150}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF
)"

  # Finder sees a fresh volume a moment after it mounts.
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if osascript -e "$script" >/dev/null 2>&1; then
      sync
      echo "    window laid out"
      return 0
    fi
    sleep 1
  done
  echo "    Finder layout skipped (allow Automation for your terminal to get it)."
}

make_dmg() {
  echo "==> DMG"
  local layout scratch rw device mount size_mb

  layout="$(mktemp -d)/$VOLUME"
  scratch="$(mktemp -d)"
  rw="$scratch/ferret-rw.dmg"
  mkdir -p "$layout"
  ditto "$APP" "$layout/Ferret.app"
  ln -s /Applications "$layout/Applications"

  if hdiutil info | grep -q "/Volumes/$VOLUME\$"; then
    echo "A volume named $VOLUME is already mounted. Eject it first." >&2
    exit 1
  fi
  # Room for Finder's .DS_Store on top of the app.
  size_mb="$(($(du -sm "$layout" | cut -f1) + 20))"
  hdiutil create -quiet -volname "$VOLUME" -srcfolder "$layout" -fs HFS+ -format UDRW -size "${size_mb}m" -ov "$rw"
  device="$(hdiutil attach -readwrite -noverify -noautoopen "$rw" | awk '/Apple_HFS/ {print $1}')"
  mount="/Volumes/$VOLUME"
  style_window
  cp "$APP/Contents/Resources/AppIcon.icns" "$mount/.VolumeIcon.icns"
  SetFile -a C "$mount"
  sync
  hdiutil detach -quiet "$device"

  if [ -f "$DMG" ]; then
    mv "$DMG" "$scratch/"
  fi
  hdiutil convert -quiet "$rw" -format ULFO -o "$DMG"

  echo "==> Signing the DMG"
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  codesign --verify --strict --verbose=2 "$DMG"
}

check_dmg() {
  echo "==> Checking the app inside the DMG"
  local mount

  mount="$(mktemp -d)"
  hdiutil attach -quiet -readonly -nobrowse -mountpoint "$mount" "$DMG"
  codesign --verify --deep --strict --verbose=2 "$mount/Ferret.app" || {
    hdiutil detach -quiet "$mount"
    exit 1
  }
  hdiutil detach -quiet "$mount"
}

notarize() {
  local profile="${FERRET_NOTARY_PROFILE:-}"

  if [ ! -f "$DMG" ]; then
    echo "No $DMG yet. Run scripts/package_macos.sh first." >&2
    exit 1
  fi
  if [ -z "$profile" ]; then
    cat <<EOF

The DMG is signed: $DMG

Notarizing uploads it to Apple. When you're ready:

  xcrun notarytool submit "$DMG" --keychain-profile <profile> --wait
  xcrun stapler staple "$DMG"

or set FERRET_NOTARY_PROFILE and run: scripts/package_macos.sh notarize
EOF
    return 0
  fi

  echo "==> Notarizing (uploads the DMG to Apple)"
  xcrun notarytool submit "$DMG" --keychain-profile "$profile" --wait

  echo "==> Stapling"
  xcrun stapler staple "$DMG"
  # The DMG's ticket covers the app inside it, so the app staples too.
  xcrun stapler staple "$APP"

  echo "==> Gatekeeper"
  spctl -a -vv -t install "$DMG"
  spctl -a -vv "$APP"

  echo "==> Zip for Homebrew and direct download"
  if [ -f "$ZIP" ]; then
    mv "$ZIP" "$(mktemp -d)/"
  fi
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

  # The landing page's Download button points at a name that never changes:
  # releases/latest/download/Ferret-mac.dmg.
  cp -f "$DMG" "$OUT/Ferret-mac.dmg"

  echo
  echo "Done:"
  shasum -a 256 "$DMG" "$ZIP" "$OUT/Ferret-mac.dmg"
}

case "$target" in
  build)
    mkdir -p "$OUT"
    build_app
    add_cli
    verify_app
    make_dmg
    check_dmg
    notarize
    ;;
  notarize)
    notarize
    ;;
  *)
    echo "Usage: scripts/package_macos.sh [build|notarize]" >&2
    exit 1
    ;;
esac
