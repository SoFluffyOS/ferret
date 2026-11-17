#!/usr/bin/env bash
# Runs a command while holding a named lock, so parallel work never runs the
# same shared step at once: scripts/with_lock.sh pub fvm flutter pub get
set -euo pipefail

name="$1"
shift

lock="${TMPDIR:-/tmp}/ferret-$name.lock"
until mkdir "$lock" 2>/dev/null; do
  holder="$(cat "$lock/pid" 2>/dev/null || true)"
  if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
    mv "$lock" "$lock.stale.$$" 2>/dev/null || true
    continue
  fi
  sleep 1
done
echo $$ > "$lock/pid"
trap 'mv "$lock" "$lock.done.$$" 2>/dev/null || true' EXIT

"$@"
