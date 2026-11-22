#!/usr/bin/env bash
# Runs an older Ferret against this checkout on loopback: pairing, clipboard
# and a file both ways, keepalives, reconnects, and what each one writes and
# reads for discovery. Usage: scripts/mixed_versions.sh <older commit>
# MIXED_QUICK=1 skips the 80-second keepalive wait.
#
# The older commit goes into a temporary git worktree (with its own
# sofluffy_ui and sofluffy_texture), which is removed again at the end. Each
# side keeps its data in its own folder under the printed work folder, never
# in ~/.sofluffy/ferret.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ref="${1:?usage: scripts/mixed_versions.sh <older commit>}"
work="$(mktemp -d "${TMPDIR:-/tmp}/ferret-mixed.XXXXXX")"
old="$work/old"

cleanup() {
  for sub in sofluffy_ui sofluffy_texture; do
    if [ -e "$old/packages/$sub/.git" ]; then
      git -C "$ROOT/packages/$sub" worktree remove --force "$old/packages/$sub" || true
    fi
  done
  git -C "$ROOT" worktree remove --force "$old" || true
}
trap cleanup EXIT

git -C "$ROOT" worktree add --detach "$old" "$ref" >/dev/null
for sub in sofluffy_ui sofluffy_texture; do
  pinned="$(git -C "$old" ls-tree HEAD "packages/$sub" | awk '{print $3}')"
  git -C "$ROOT/packages/$sub" worktree add --detach "$old/packages/$sub" "$pinned" >/dev/null
done

mkdir -p "$old/apps/ferret/test/mixed"
cp "$ROOT/apps/ferret/test/mixed/mixed_peer_test.dart" "$old/apps/ferret/test/mixed/"
(cd "$old" && fvm flutter pub get >/dev/null)

echo "Work folder: $work"
fvm dart "$ROOT/scripts/mixed_versions.dart" "$old" "$ROOT" "$work/run"
