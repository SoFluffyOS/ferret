#!/usr/bin/env bash
# Builds the Mac release from a tag and adds it to that tag's DRAFT GitHub
# release (the one .github/workflows/release.yml made):
#
#   FERRET_NOTARY_PROFILE=<profile> scripts/upload_mac_release.sh v0.1.0
#
# It builds in a temporary git worktree checked out at the tag, so your own
# checkout and any uncommitted work stay as they are. Then it signs, notarizes
# and staples (scripts/package_macos.sh), merges the Mac lines into the
# release's SHA256SUMS (Ferret's updater refuses any download not listed
# there), and uploads the DMG, the zip, Ferret-mac.dmg and the new SHA256SUMS.
#
# Needs: the Developer ID certificate in the keychain, a notarytool keychain
# profile (packaging/macos/README.md), and gh signed in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tag="${1:?Usage: FERRET_NOTARY_PROFILE=<profile> scripts/upload_mac_release.sh <tag>}"
repo="SoFluffyOS/ferret"

[ -n "${FERRET_NOTARY_PROFILE:-}" ] || {
  echo "Set FERRET_NOTARY_PROFILE: a release DMG must be notarized." >&2
  exit 1
}

if [ "$(gh release view "$tag" -R "$repo" --json isDraft -q .isDraft 2>/dev/null)" != true ]; then
  echo "No draft release for $tag. Push the tag and wait for the Release workflow first." >&2
  exit 1
fi

git -C "$ROOT" fetch --quiet origin "refs/tags/$tag:refs/tags/$tag"
tree="$(mktemp -d)/ferret-$tag"
git -C "$ROOT" worktree add --quiet --detach "$tree" "$tag"
cleanup() { git -C "$ROOT" worktree remove --force "$tree" 2>/dev/null || true; }
trap cleanup EXIT

echo "==> Building $tag in $tree"
git -C "$tree" submodule update --init --recursive --quiet
(cd "$tree" && scripts/package_macos.sh)

out="$tree/build/macos-packages"
version="${tag#v}"
files=("Ferret-$version.dmg" "Ferret-$version-mac.zip" "Ferret-mac.dmg")
for file in "${files[@]}"; do
  [ -f "$out/$file" ] || { echo "Missing $out/$file" >&2; exit 1; }
done

echo "==> Merging SHA256SUMS"
scratch="$(mktemp -d)"
gh release download "$tag" -R "$repo" --pattern SHA256SUMS --dir "$scratch"
# The fresh Mac lines win over any older ones with the same name.
awk '!seen[$2]++' "$out/SHA256SUMS" "$scratch/SHA256SUMS" | sort -k2 >"$scratch/merged"
mv "$scratch/merged" "$scratch/SHA256SUMS"
(cd "$out" && shasum -a 256 -c <(grep -E "  (Ferret-$version\.dmg|Ferret-$version-mac\.zip|Ferret-mac\.dmg)$" "$scratch/SHA256SUMS"))
cat "$scratch/SHA256SUMS"

echo "==> Uploading to the $tag draft"
gh release upload "$tag" -R "$repo" --clobber \
  "$out/Ferret-$version.dmg" "$out/Ferret-$version-mac.zip" "$out/Ferret-mac.dmg" "$scratch/SHA256SUMS"

echo
echo "Done. Open the draft, delete its draft notes, and Publish:"
gh release view "$tag" -R "$repo" --json url -q .url
