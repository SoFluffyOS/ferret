#!/usr/bin/env bash
# Generates Dart from this package's proto/ into lib/proto/generated.
# Needs protoc and protoc-gen-dart (dart pub global activate protoc_plugin).
set -euo pipefail

PACKAGE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.pub-cache/bin:$PATH"

OUT="$PACKAGE/lib/proto/generated"
find "$OUT" -name '*.dart' -delete 2>/dev/null || true
mkdir -p "$OUT"

cd "$PACKAGE/proto"
protoc --dart_out="$OUT" quickshare/*.proto
find "$OUT" \( -name '*.pbjson.dart' -o -name '*.pbserver.dart' \) -delete

echo "Generated $(find "$OUT" -name '*.pb.dart' | wc -l | tr -d ' ') proto files."
