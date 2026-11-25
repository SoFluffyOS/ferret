// What Ferret draws before it is ready: the launch look on a phone (and the
// quiet spinner a slow start adds), a computer window's background, and the
// page a failed start shows. Renders into temp/screens as
// `boot_<name>_<size>_<mode>.png`. Run from apps/ferret:
//
//   flutter test test/screens/boot_screens_test.dart
@Tags(['screens'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

void main() {
  setUpAll(loadScreenFonts);

  Future<void> capture(
    WidgetTester tester,
    String name,
    Size size,
    Brightness brightness,
    Widget child,
  ) async {
    final boundary = GlobalKey();
    tester.view
      ..physicalSize = size * capturePixelRatio
      ..devicePixelRatio = capturePixelRatio;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(RepaintBoundary(key: boundary, child: child));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final render = boundary.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary) {
      throw StateError('Nothing to capture for $name.');
    }
    applyScreenFont(render);
    tester.binding.rootPipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: capturePixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await screensDirectory.create(recursive: true);
      final mode = switch (brightness) {
        Brightness.light => 'light',
        Brightness.dark => 'dark',
      };
      await File(
        '${screensDirectory.path}/boot_${name}_$mode.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox.shrink());
  }

  const phoneSize = Size(412, 915);
  const iphoneSize = Size(390, 844);
  const windowSize = Size(900, 640);

  for (final brightness in Brightness.values) {
    testWidgets('launch look, ${brightness.name}', (tester) async {
      debugDefaultTargetPlatformOverride = .android;
      await capture(
        tester,
        'starting_phone',
        phoneSize,
        brightness,
        const BootScreen(
          look: SplashLook.android,
          spinnerAfter: Duration(hours: 1),
        ),
      );
      await capture(
        tester,
        'slow_phone',
        phoneSize,
        brightness,
        const BootScreen(look: SplashLook.android),
      );
      debugDefaultTargetPlatformOverride = .iOS;
      await capture(
        tester,
        'starting_iphone',
        iphoneSize,
        brightness,
        const BootScreen(
          look: SplashLook.iOS,
          spinnerAfter: Duration(hours: 1),
        ),
      );
      debugDefaultTargetPlatformOverride = .windows;
      await capture(
        tester,
        'slow_window',
        windowSize,
        brightness,
        const BootScreen(look: null),
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('failed start, ${brightness.name}', (tester) async {
      debugDefaultTargetPlatformOverride = .android;
      await capture(
        tester,
        'failed_phone',
        phoneSize,
        brightness,
        BootFailure(onRetry: () {}, isRetrying: false),
      );
      debugDefaultTargetPlatformOverride = .macOS;
      await capture(
        tester,
        'failed_popover',
        const Size(380, 560),
        brightness,
        BootFailure(onRetry: () {}, isRetrying: false),
      );
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
