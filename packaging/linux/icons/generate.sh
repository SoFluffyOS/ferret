#!/usr/bin/env bash
# Writes the hicolor set from branding/ferret-icon.svg: the SVG itself as the
# scalable icon, and PNGs at every size. Needs rsvg-convert (librsvg); runs on
# macOS too. scripts/generate_icons.sh calls it with the other platforms.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$(dirname "${BASH_SOURCE[0]}")/hicolor"

mkdir -p scalable/apps
cp "$root/branding/ferret-icon.svg" scalable/apps/io.sofluffy.ferret.svg

for size in 16 24 32 48 64 128 256 512; do
  mkdir -p "${size}x${size}/apps"
  rsvg-convert -w "$size" -h "$size" scalable/apps/io.sofluffy.ferret.svg -o "${size}x${size}/apps/io.sofluffy.ferret.png"
done
