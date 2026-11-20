#!/bin/sh
# Installs Ferret on Linux from the latest GitHub release, just for you:
#
#   curl -fsSL ferret.sofluffy.io/install.sh | sh
#
# It puts the AppImage in ~/.local/opt/ferret, links `ferret` and
# `ferret-cli` in ~/.local/bin, and adds Ferret to your app menu. No sudo.
# Run it again to update. FERRET_VERSION=v0.1.0 picks a release.

set -eu

APP_ID="io.sofluffy.ferret"
REPO="simonpham/ferret"
API_ROOT="https://api.github.com/repos/$REPO/releases"
INSTALL_DIR="${FERRET_INSTALL_DIR:-$HOME/.local/opt/ferret}"
BIN_DIR="${FERRET_BIN_DIR:-$HOME/.local/bin}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DESKTOP_DIR="$DATA_HOME/applications"
ICON_DIR="$DATA_HOME/icons/hicolor/256x256/apps"
VERSION="${FERRET_VERSION:-latest}"

say() { printf '%s\n' "$1"; }
fail() { printf 'Error: %s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "missing required command '$1'"; }

[ "$(uname -s)" = "Linux" ] || fail "this installer is for Linux. Get Ferret for your system at https://ferret.sofluffy.io"

case "$(uname -m)" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="aarch64" ;;
  *) fail "no Ferret build for '$(uname -m)' yet" ;;
esac

need curl
need mktemp
need sed
need install

github() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL -H "User-Agent: Ferret-Installer" -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" "$@"
  else
    curl -fsSL -H "User-Agent: Ferret-Installer" -H "Accept: application/vnd.github+json" "$@"
  fi
}

if [ "$VERSION" = "latest" ]; then
  RELEASE_URL="$API_ROOT/latest"
else
  RELEASE_URL="$API_ROOT/tags/$VERSION"
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

say "Looking for Ferret for $ARCH…"
RELEASE_JSON=$(github "$RELEASE_URL") \
  || fail "couldn't read the release from GitHub. Hit the rate limit? Try again with GITHUB_TOKEN set."

DOWNLOAD_URL=$(
  printf '%s' "$RELEASE_JSON" \
    | tr ',' '\n' \
    | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | grep "/Ferret-.*-$ARCH\.AppImage$" \
    | head -n 1 \
    || true
)
[ -n "$DOWNLOAD_URL" ] || fail "no AppImage for $ARCH in release '$VERSION'"

say "Downloading $(basename "$DOWNLOAD_URL")…"
curl -fL --progress-bar -H "User-Agent: Ferret-Installer" "$DOWNLOAD_URL" -o "$TMP_DIR/Ferret.AppImage" \
  || fail "the download didn't finish"
chmod +x "$TMP_DIR/Ferret.AppImage"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR"
mv -f "$TMP_DIR/Ferret.AppImage" "$INSTALL_DIR/Ferret.AppImage"
APPIMAGE="$INSTALL_DIR/Ferret.AppImage"

ln -sfn "$APPIMAGE" "$BIN_DIR/ferret"
# The AppImage runs the command line when it's started as ferret-cli.
ln -sfn "$APPIMAGE" "$BIN_DIR/ferret-cli"

# The app menu entry and icon come from inside the AppImage. Extracting
# works without FUSE.
(
  cd "$TMP_DIR"
  "$APPIMAGE" --appimage-extract "$APP_ID.desktop" >/dev/null 2>&1 || true
  "$APPIMAGE" --appimage-extract "$APP_ID.png" >/dev/null 2>&1 || true
)
if [ -f "$TMP_DIR/squashfs-root/$APP_ID.png" ]; then
  install -m 0644 "$TMP_DIR/squashfs-root/$APP_ID.png" "$ICON_DIR/$APP_ID.png"
fi
if [ -f "$TMP_DIR/squashfs-root/$APP_ID.desktop" ]; then
  sed -e "s|^Exec=[^ ]*|Exec=$APPIMAGE|" \
      -e "s|^TryExec=.*|TryExec=$APPIMAGE|" \
      "$TMP_DIR/squashfs-root/$APP_ID.desktop" > "$TMP_DIR/$APP_ID.desktop"
  install -m 0644 "$TMP_DIR/$APP_ID.desktop" "$DESKTOP_DIR/$APP_ID.desktop"
  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi

say ""
say "Ferret is installed. Open it from your app menu, or run: ferret"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say "Add $BIN_DIR to your PATH to run ferret and ferret-cli from a terminal." ;;
esac

if ! ldconfig -p 2>/dev/null | grep -q "libfuse.so.2"; then
  say "AppImages need FUSE 2 to start. Ubuntu/Debian: sudo apt install libfuse2t64 (or libfuse2). Fedora: sudo dnf install fuse-libs."
fi

say "Next: open Ferret on your phone too, on the same Wi-Fi, and tap Pair."
