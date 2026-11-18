/// A mirroring route for Android devices over adb: scrcpy's official
/// server captures the screen on the device, and this package reads it.
library;

export 'package:ferret_mirror_scrcpy/src/adb/adb.dart';
export 'package:ferret_mirror_scrcpy/src/download/download.dart';
export 'package:ferret_mirror_scrcpy/src/protocol/protocol.dart';
export 'package:ferret_mirror_scrcpy/src/route/route.dart';
export 'package:ferret_mirror_scrcpy/src/server/server.dart';
