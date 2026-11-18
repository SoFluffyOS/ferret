# Runs inside the Magisk (or KernelSU / APatch) module installer, which
# provides ui_print, abort, set_perm, set_perm_recursive, $MODPATH, $API and
# $ARCH. See https://topjohnwu.github.io/Magisk/guides.html
#
# RUNTIME-UNTESTED: this script has been checked with `sh -n` only. It has
# never been flashed on a device.

APP_DIR="$MODPATH/system/priv-app/Ferret"
APK="$APP_DIR/Ferret.apk"
PACKAGE="io.sofluffy.ferret"

ui_print "- Ferret privileged install (experimental)"

if [ "$API" -lt 26 ]; then
  abort "! Android 8.0 or later is needed (this is API $API)."
fi

if [ ! -f "$APK" ]; then
  abort "! Ferret.apk is missing from the module. Build it with magisk/build.sh."
fi

# A privileged app loads its native libraries from next to the APK, so the
# ones for this device's CPU are unpacked there.
case "$ARCH" in
  arm64) ABI="arm64-v8a"; LIB_DIR="arm64" ;;
  arm) ABI="armeabi-v7a"; LIB_DIR="arm" ;;
  x64) ABI="x86_64"; LIB_DIR="x86_64" ;;
  x86) ABI="x86"; LIB_DIR="x86" ;;
  *) abort "! Unknown CPU type: $ARCH" ;;
esac

if unzip -l "$APK" "lib/$ABI/*" >/dev/null 2>&1; then
  ui_print "- Unpacking native libraries for $ABI"
  mkdir -p "$APP_DIR/lib/$LIB_DIR"
  unzip -o -j "$APK" "lib/$ABI/*" -d "$APP_DIR/lib/$LIB_DIR" >/dev/null ||
    abort "! Could not unpack the native libraries."
else
  abort "! This APK has no libraries for $ABI. Build a release APK that includes it."
fi

# The same package installed as a normal app with another signing key makes
# Android refuse the system copy at boot. Say so now, not after a reboot.
if pm path "$PACKAGE" >/dev/null 2>&1; then
  ui_print "- Ferret is already installed as a normal app."
  ui_print "  The APK in this module must be signed with the same key,"
  ui_print "  or Android will ignore it. If unsure, uninstall Ferret"
  ui_print "  first (you will pair your devices again)."
fi

set_perm_recursive "$MODPATH/system" 0 0 0755 0644
ui_print "- Done. Restart your phone to finish."
