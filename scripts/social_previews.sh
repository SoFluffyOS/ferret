#!/usr/bin/env bash
# Renders the link previews from apps/ferret_docs/tool/social/preview.html
# with headless Chrome (no window opens):
#
#   apps/ferret_docs/web/images/social-landing.png   1200x630, the landing's og:image
#   build/social/github-social-preview.png           1280x640, upload by hand in the
#                                                    repo's Settings → Social preview
#
# Run it after the landing renders change (docs/assets/landing/window-overview-*).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGE="$ROOT/apps/ferret_docs/tool/social/preview.html"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || { echo "Chrome not found; set CHROME to its binary." >&2; exit 1; }

profile="$(mktemp -d)"
shot() {
  local size="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --force-device-scale-factor=1 --window-size="$size" --virtual-time-budget=3000 \
    --user-data-dir="$profile" --screenshot="$out" "file://$PAGE" >/dev/null 2>&1
  # Same bytes on every run: no time stamps in the PNG.
  magick "$out" -define png:exclude-chunk=date,time "PNG24:$out"
  echo "    $out"
}

echo "==> Link previews"
shot 1200,630 "$ROOT/apps/ferret_docs/web/images/social-landing.png"
shot 1280,640 "$ROOT/build/social/github-social-preview.png"
