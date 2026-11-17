#!/usr/bin/env bash
# Generates Dart from proto/ into packages/protocol and rewrites its barrel.
set -euo pipefail

if [ -z "${FERRET_GEN_LOCKED:-}" ]; then
  FERRET_GEN_LOCKED=1 exec "$(dirname "${BASH_SOURCE[0]}")/with_lock.sh" gen "${BASH_SOURCE[0]}" "$@"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUF="${BUF:-$(command -v buf || echo "$HOME/.local/bin/buf")}"
export PATH="$HOME/.pub-cache/bin:$PATH"

GENERATED="$ROOT/packages/protocol/lib/src/generated"

cd "$ROOT/proto"
"$BUF" lint
"$BUF" format -w

find "$GENERATED" -name '*.dart' -delete 2>/dev/null || true
mkdir -p "$GENERATED"
"$BUF" generate

# One barrel per proto package: ferret/v1 -> protocol.dart, ferret/<feature>/v1 -> <feature>.dart.
find "$ROOT/packages/protocol/lib" -maxdepth 1 -name '*.dart' -delete
for dir in $(cd "$GENERATED" && find ferret -name '*.pb.dart' -exec dirname {} \; | sort -u); do
  case "$dir" in
    ferret/v1) name=protocol ;;
    ferret/*/v*) name="$(basename "$(dirname "$dir")")" ;;
    *) continue ;;
  esac

  {
    echo "/// Generated from proto/$dir by scripts/gen.sh. Do not edit."
    echo 'library;'
    echo
    (cd "$ROOT/packages/protocol/lib" && find "src/generated/$dir" -maxdepth 1 \( -name '*.pb.dart' -o -name '*.pbenum.dart' \) | sort) |
      while read -r file; do
        echo "export 'package:protocol/$file';"
      done
    if [ "$name" = protocol ]; then
      echo "export 'package:protocol/src/payload.dart';"
    fi
  } > "$ROOT/packages/protocol/lib/$name.dart"
done

echo "Generated $(find "$GENERATED" -name '*.pb.dart' | wc -l | tr -d ' ') proto files."
fvm dart format "$ROOT/packages/protocol/lib"/*.dart >/dev/null
