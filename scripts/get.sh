#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/sdk.sh
. "$(dirname "${BASH_SOURCE[0]}")/sdk.sh"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
git submodule update --init --recursive
"${FLUTTER[@]}" pub get
