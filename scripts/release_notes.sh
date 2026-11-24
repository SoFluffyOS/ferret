#!/usr/bin/env bash
# Prints one version's section of CHANGELOG.md, without its heading: the
# GitHub release notes.
#
#   scripts/release_notes.sh 0.1.0        the "## [0.1.0] - <date>" section
#   scripts/release_notes.sh Unreleased   what the next release will say
#
# Fails when the section is missing or empty, so a tag never ships without
# notes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${1:?Usage: scripts/release_notes.sh <version>}"

notes="$(awk -v want="$version" '
  /^## \[/ {
    if (found) exit
    heading = $0
    sub(/^## \[/, "", heading)
    sub(/\].*$/, "", heading)
    if (heading == want) { found = 1; next }
  }
  found { print }
' "$ROOT/CHANGELOG.md")"

# Trim blank lines at both ends.
notes="$(printf '%s\n' "$notes" | sed -e '/./,$!d' | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}')"

if [ -z "$notes" ]; then
  echo "CHANGELOG.md has no \"## [$version]\" section, or it is empty." >&2
  echo "Rename \"## [Unreleased]\" to \"## [$version] - $(date +%Y-%m-%d)\" before tagging." >&2
  exit 1
fi

# Links into docs/ are relative in the changelog; on the release page they
# point at the website instead.
printf '%s\n' "$notes" | sed -E 's#\]\(docs/([^)#]*)\.md#](https://ferret.sofluffy.io/docs/\1#g'
