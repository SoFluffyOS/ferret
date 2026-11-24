# Sourced by the other scripts: which Flutter and Dart to run.
#
# With fvm installed and a .fvmrc in the repo, they go through fvm, so the
# pinned SDK is used. Otherwise it's the `flutter` and `dart` on your PATH:
# a global install, puro, or anything else. Use the latest stable Flutter.
#
#   "${FLUTTER[@]}" pub get
#   "${DART[@]}" format lib
#
# FERRET_NO_FVM=1 skips fvm even when it's installed.

_sdk_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -z "${FERRET_NO_FVM:-}" ] && command -v fvm >/dev/null 2>&1 && [ -f "$_sdk_root/.fvmrc" ]; then
  FLUTTER=(fvm flutter)
  DART=(fvm dart)
else
  FLUTTER=(flutter)
  DART=(dart)
fi
unset _sdk_root
