import 'dart:io';

import 'package:ferret_mirroring/src/messages.g.dart';

/// Full screen for the window the mirror is shown in, where the platform
/// and the window allow it.
abstract interface class MirrorWindow {
  static MirrorWindow current() {
    if (Platform.isMacOS) {
      return MacMirrorWindow();
    }

    return const FixedMirrorWindow();
  }

  /// False in windows that can't, such as the macOS menubar popover.
  Future<bool> canFullScreen();

  Future<bool> isFullScreen();

  Future<void> setFullScreen(bool fullScreen);
}

/// A window that stays as it is: platforms without native window code.
class FixedMirrorWindow implements MirrorWindow {
  const FixedMirrorWindow();

  @override
  Future<bool> canFullScreen() async => false;

  @override
  Future<bool> isFullScreen() async => false;

  @override
  Future<void> setFullScreen(bool fullScreen) async {}
}

class MacMirrorWindow implements MirrorWindow {
  MacMirrorWindow({MirrorDecoderHostApi? api})
    : _api = api ?? MirrorDecoderHostApi();

  final MirrorDecoderHostApi _api;

  @override
  Future<bool> canFullScreen() async {
    try {
      return await _api.canFullScreen();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> isFullScreen() async {
    try {
      return await _api.isFullScreen();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setFullScreen(bool fullScreen) async {
    try {
      await _api.setFullScreen(fullScreen);
    } on Object {
      return;
    }
  }
}
