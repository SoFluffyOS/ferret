#!/usr/bin/env bash
# The site: the landing page at /, and the docs read from docs in
# place (nothing is copied) and served under /docs.
#   scripts/docs.sh serve       live preview on http://localhost:8080
#   scripts/docs.sh check       links, images, internal links, protocol reference
#   scripts/docs.sh reference   regenerate docs/spec/reference.md from proto/
#   scripts/docs.sh build [dir] check, then a static site (default apps/ferret_docs/build/jaspr)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$ROOT/apps/ferret_docs"
cd "$DOCS"

# With fvm, the docs site builds with the SDK pinned in apps/ferret_docs/.fvmrc;
# otherwise with the Flutter on your PATH (its dart).
if [ -z "${FERRET_NO_FVM:-}" ] && command -v fvm >/dev/null 2>&1; then
  fvm install >/dev/null 2>&1 || true
  fvm use --force >/dev/null 2>&1 || true
  export PATH="$DOCS/.fvm/flutter_sdk/bin:$PATH"
fi
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
    $JASPR build \
      --sitemap-domain https://ferret.sofluffy.io \
      --sitemap-exclude '^/404'
    # The landing and 404 pages have no client components; Jaspr adds its
    # client script to every page anyway, so these two drop it.
    for page in build/jaspr/index.html build/jaspr/404.html; do
      sed -i.bak 's#<script src="main.client.dart.js" defer></script>##' "$page"
      rm "$page.bak"
    done
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
