import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> steps;

  setUp(() {
    steps = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  AppQuit quitter({Future<void> Function()? shutdown}) => AppQuit(
    shutdown: shutdown ?? () async => steps.add('shutdown'),
    exitPlatform: () async => steps.add('exit'),
    timeout: const Duration(milliseconds: 50),
  );

  test('quit says goodbye before the app ends', () async {
    await quitter().quit();

    expect(steps, ['shutdown', 'exit']);
  });

  test('a quit the system starts waits for the goodbye', () async {
    final response = await quitter().didRequestAppExit();

    expect(response, AppExitResponse.exit);
    expect(steps, ['shutdown']);
  });

  test('every way out shuts down only once', () async {
    final quit = quitter();

    await quit.quit();
    await quit.didRequestAppExit();
    quit.didChangeAppLifecycleState(.detached);
    await quit.shutDown();

    expect(steps.where((step) => step == 'shutdown'), hasLength(1));
  });

  test('a shutdown that hangs still lets the app quit', () async {
    final quit = quitter(shutdown: () => Completer<void>().future);

    await quit.quit();

    expect(steps, ['exit']);
  });

  test('a failing shutdown still lets the app quit', () async {
    final quit = quitter(shutdown: () async => throw StateError('closed'));

    await quit.quit();

    expect(steps, ['exit']);
  });

  test('on Android the service keeps Ferret running after Quit', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final quit = quitter();

    await quit.quit();
    quit.didChangeAppLifecycleState(.detached);
    await quit.didRequestAppExit();

    expect(steps, ['exit']);
  });
}
