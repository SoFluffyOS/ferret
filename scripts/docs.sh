#!/usr/bin/env bash
# The docs site reads docs/public in place; nothing is copied.
#   scripts/docs.sh serve       live preview on http://localhost:8080
#   scripts/docs.sh check       links, images, internal links, protocol reference
#   scripts/docs.sh reference   regenerate docs/public/spec/reference.md from proto/
#   scripts/docs.sh build [dir] check, then a static site (default apps/ferret_docs/build/jaspr)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$ROOT/apps/ferret_docs"
cd "$DOCS"

# The docs site builds with the SDK pinned in apps/ferret_docs/.fvmrc.
fvm install >/dev/null 2>&1 || true
fvm use --force >/dev/null 2>&1 || true
export PATH="$DOCS/.fvm/flutter_sdk/bin:$PATH"
dart pub get >/dev/null

JASPR="dart run jaspr_cli:jaspr"

case "${1:-check}" in
  serve)
    $JASPR serve
    ;;
  reference)
    dart run tool/gen_proto_reference.dart
    ;;
  check)
    dart run tool/check_docs.dart
    ;;
  build)
    dart run tool/check_docs.dart
    $JASPR build
    if [ -n "${2:-}" ]; then
      mkdir -p "$2"
      cp -R build/jaspr/. "$2/"
      echo "Copied the site to $2"
    fi
    ;;
  *)
    echo "Usage: scripts/docs.sh serve|check|reference|build [dir]" >&2
    exit 2
    ;;
esac
