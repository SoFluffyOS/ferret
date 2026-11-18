#!/usr/bin/env bash
# Formats, analyzes and tests one package (scripts/check.sh packages/engine) or
# every workspace member. Exits non-zero on the first failure.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ $# -gt 0 ]; then
  targets=("$@")
else
  targets=()
  while read -r member; do targets+=("$member"); done < <(sed -n 's/^  - //p' pubspec.yaml)
fi

for target in "${targets[@]}"; do
  echo "==> $target"
  (
    cd "$ROOT/$target"
    files=()
    while read -r file; do files+=("$file"); done < <(find . -name '*.dart' -not -path '*/generated/*' -not -path './.dart_tool/*' -not -path '*/build/*' -not -name '*.pb*.dart' -not -name '*.g.dart')
    if [ ${#files[@]} -gt 0 ] && ! fvm dart format --set-exit-if-changed "${files[@]}" >/dev/null; then
      echo "   formatted files; review and re-run"
      exit 1
    fi
    fvm dart analyze --fatal-infos .
    if [ -d test ] && [ -n "$(find test -name '*_test.dart' -print -quit)" ]; then
      if grep -q 'sdk: flutter' pubspec.yaml; then
        fvm flutter test --exclude-tags screens
      else
        fvm dart test
      fi
    fi
  )
done
