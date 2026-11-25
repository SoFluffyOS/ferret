# Sourced by the other scripts: which Flutter and Dart to run.
#
# Puro, fvm or the Flutter on your PATH — whichever is installed, in that
# order. Pin a version locally with puro or fvm if you like; the repo
# doesn't commit a pin.
#
#   "${FLUTTER[@]}" pub get
#   "${DART[@]}" format lib

if command -v puro >/dev/null 2>&1; then
  FLUTTER=(puro flutter)
  DART=(puro dart)
elif command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
  DART=(fvm dart)
else
  FLUTTER=(flutter)
  DART=(dart)
fi
