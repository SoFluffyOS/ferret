#!/usr/bin/env bash
# Renders the hicolor PNGs from scalable/apps/io.sofluffy.ferret.svg (the
# docs logo on a square canvas). Needs ImageMagick 7; runs on macOS too.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/hicolor"
svg=scalable/apps/io.sofluffy.ferret.svg

for size in 16 24 32 48 64 128 256 512; do
  mkdir -p "${size}x${size}/apps"
  magick -background none -density 600 "$svg" -resize "${size}x${size}" \
    -gravity center -extent "${size}x${size}" "PNG32:${size}x${size}/apps/io.sofluffy.ferret.png"
done
