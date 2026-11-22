#!/usr/bin/env bash
# Builds Ferret's Linux packages from packaging/linux into build/linux-packages:
#
#   scripts/package_linux.sh [deb|appimage|flatpak|all]   (default: all)
#
# Runs on Linux only (x86_64 or aarch64): Flutter can't cross-build a Linux
# app from macOS or Windows. Every target first builds the release bundle
# (fvm flutter build linux) and ferret-cli (dart compile exe).
#
# Needs: fvm, clang, cmake, ninja, pkg-config and libgtk-3-dev for Flutter;
#   deb       dpkg-deb
#   appimage  appimagetool (https://github.com/AppImage/appimagetool, the
#             static runtime, so users don't need libfuse2), or set APPIMAGETOOL
#   flatpak   flatpak-builder, and org.freedesktop.Platform/Sdk 25.08 from Flathub
#
# FERRET_DEB_MAINTAINER sets the .deb's Maintainer ("Name <email>"); it
# defaults to your git name and email.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PACKAGING="$ROOT/packaging/linux"
OUT="$ROOT/build/linux-packages"
# The Flatpak manifest reads the stage from here. Scratch trees go to fresh
# temp folders, and an old stage is moved there, so nothing is deleted.
STAGE="$OUT/stage"
APP_ID="io.sofluffy.ferret"
target="${1:-all}"

if [ "$(uname -s)" != "Linux" ]; then
  echo "package_linux.sh builds on Linux only (this is $(uname -s))." >&2
  echo "Flutter can't cross-build a Linux app. Run it on a Linux machine or VM." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) flutter_arch=x64; deb_arch=amd64; appimage_arch=x86_64 ;;
  aarch64 | arm64) flutter_arch=arm64; deb_arch=arm64; appimage_arch=aarch64 ;;
  *) echo "Unsupported machine: $(uname -m)" >&2; exit 1 ;;
esac

version="$(sed -n 's/^version: *\([^+]*\).*/\1/p' apps/ferret/pubspec.yaml)"

build_stage() {
  echo "==> Flutter bundle and ferret-cli ($version, $flutter_arch)"
  (cd apps/ferret && fvm flutter build linux --release)
  if [ -d "$STAGE" ]; then
    mv "$STAGE" "$(mktemp -d)/"
  fi
  mkdir -p "$STAGE"
  cp -r "apps/ferret/build/linux/$flutter_arch/release/bundle" "$STAGE/bundle"
  (cd apps/ferret_cli && fvm dart compile exe bin/ferret.dart -o "$STAGE/ferret-cli")
}

# Lays out an install tree: <root><prefix>/lib/ferret holds the bundle,
# <prefix>/bin the two commands, <prefix>/share the desktop integration.
install_tree() {
  local root="$1" prefix="$2"
  local lib="$root$prefix/lib/ferret" share="$root$prefix/share"

  mkdir -p "$lib" "$root$prefix/bin" "$share/applications" "$share/metainfo" "$share/icons"
  cp -r "$STAGE/bundle/." "$lib/"
  ln -sf ../lib/ferret/ferret "$root$prefix/bin/ferret"
  install -m755 "$STAGE/ferret-cli" "$root$prefix/bin/ferret-cli"
  install -m644 "$PACKAGING/$APP_ID.desktop" "$PACKAGING/$APP_ID.send.desktop" "$share/applications/"
  install -m644 "$PACKAGING/$APP_ID.metainfo.xml" "$share/metainfo/"
  cp -r "$PACKAGING/icons/hicolor" "$share/icons/"
}

build_deb() {
  echo "==> .deb"
  local root
  root="$(mktemp -d)"
  local maintainer="${FERRET_DEB_MAINTAINER:-$(git config user.name) <$(git config user.email)>}"

  install_tree "$root" /usr
  install -Dm644 "$PACKAGING/firewall/ferret.ufw" "$root/etc/ufw/applications.d/ferret"
  install -Dm644 "$PACKAGING/firewall/ferret.firewalld.xml" "$root/usr/lib/firewalld/services/ferret.xml"

  mkdir -p "$root/DEBIAN"
  sed -e "s/@VERSION@/$version/" -e "s/@ARCH@/$deb_arch/" \
    -e "s/@SIZE@/$(du -sk "$root/usr" | cut -f1)/" -e "s|@MAINTAINER@|$maintainer|" \
    "$PACKAGING/deb/control.in" >"$root/DEBIAN/control"
  install -m755 "$PACKAGING/deb/postinst" "$PACKAGING/deb/postrm" "$root/DEBIAN/"

  dpkg-deb --build --root-owner-group "$root" "$OUT/ferret_${version}_${deb_arch}.deb"
}

build_appimage() {
  echo "==> AppImage"
  local appdir
  appdir="$(mktemp -d)/Ferret.AppDir"
  local tool="${APPIMAGETOOL:-appimagetool}"

  install_tree "$appdir" /usr
  install -m755 "$PACKAGING/appimage/AppRun" "$appdir/AppRun"
  cp "$PACKAGING/$APP_ID.desktop" "$appdir/"
  cp "$PACKAGING/icons/hicolor/256x256/apps/$APP_ID.png" "$appdir/$APP_ID.png"
  ln -sf "$APP_ID.png" "$appdir/.DirIcon"

  ARCH="$appimage_arch" "$tool" "$appdir" "$OUT/Ferret-$version-$appimage_arch.AppImage"
  # install.sh and Ferret's updater look for a name that never changes:
  # releases/latest/download/Ferret-linux-x86_64.AppImage.
  cp -f "$OUT/Ferret-$version-$appimage_arch.AppImage" "$OUT/Ferret-linux-$appimage_arch.AppImage"
}

# Ferret's updater refuses a download whose SHA-256 isn't in the release's
# SHA256SUMS. Merge this file with the other platforms' into the one
# SHA256SUMS the release carries.
write_sums() {
  local files=() file
  for file in "$OUT"/*"$version"* "$OUT"/Ferret-linux-*.AppImage; do
    if [ -f "$file" ]; then
      files+=("$(basename "$file")")
    fi
  done
  (cd "$OUT" && sha256sum "${files[@]}" >SHA256SUMS)
  cat "$OUT/SHA256SUMS"
}

build_flatpak() {
  echo "==> Flatpak"
  local scratch
  scratch="$(mktemp -d)"

  flatpak-builder --force-clean --user --install-deps-from=flathub \
    --state-dir="$scratch/state" --repo="$OUT/flatpak-repo" \
    "$scratch/build" "$PACKAGING/flatpak/$APP_ID.yml"
  flatpak build-bundle "$OUT/flatpak-repo" "$OUT/ferret-$version-$appimage_arch.flatpak" "$APP_ID"
}

case "$target" in
  deb) build_stage; build_deb ;;
  appimage) build_stage; build_appimage ;;
  flatpak) build_stage; build_flatpak ;;
  all) build_stage; build_deb; build_appimage; build_flatpak ;;
  *) echo "Usage: $0 [deb|appimage|flatpak|all]" >&2; exit 64 ;;
esac

write_sums
echo "Packages are in $OUT."
