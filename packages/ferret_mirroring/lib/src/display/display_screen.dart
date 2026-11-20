import 'dart:io';

import 'package:ferret_mirroring/src/display/display_capture.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// This device's own screen while it is another computer's display: its
/// size for that computer to fill, and keeping it on. For a device that
/// measures its screen in Flutter, an Android phone or tablet.
abstract final class DisplayScreen {
  static final MirrorScreenHostApi _api = MirrorScreenHostApi();

  /// [physicalSize] as the screen is held now, in pixels. A screen with
  /// [devicePixelRatio] of 1.5 or more is sharp: 2 pixels per point.
  static ScreenPanel panelOf({
    required Size physicalSize,
    required double devicePixelRatio,
    required double refreshRate,
  }) => ScreenPanel(
    width: physicalSize.width.round(),
    height: physicalSize.height.round(),
    scale: switch (devicePixelRatio >= 1.5) {
      true => 2,
      false => 1,
    },
    refreshHz: switch (refreshRate.round()) {
      < 24 => 60,
      final hz => hz,
    },
  );

  /// The screen of the app's first view, or null when there is none.
  static ScreenPanel? measure() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return null;
    }

    final view = views.first;
    if (view.physicalSize.isEmpty) {
      return null;
    }

    return panelOf(
      physicalSize: view.physicalSize,
      devicePixelRatio: view.devicePixelRatio,
      refreshRate: view.display.refreshRate,
    );
  }

  /// Keeps the screen on while [on], on Android. Nothing elsewhere.
  static Future<void> keepOn(bool on) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    try {
      await _api.keepScreenOn(on);
    } on Object catch (error) {
      debugPrint('Could not keep the screen on: $error');
    }
  }
}
