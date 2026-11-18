import 'dart:io';

import 'package:ferret_media/src/linux/linux.dart';
import 'package:ferret_media/src/media_backend.dart';
import 'package:ferret_media/src/pigeon_media_backend.dart';
import 'package:ferret_media/src/unsupported_media_backend.dart';

/// Picks the media backend for this platform.
abstract final class FerretMedia {
  static MediaBackend platform() {
    if (Platform.isLinux) {
      return MprisMediaBackend();
    }

    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows) {
      return PigeonMediaBackend();
    }

    return const UnsupportedMediaBackend();
  }
}
