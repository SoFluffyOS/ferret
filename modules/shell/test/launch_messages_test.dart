import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();

  void sendFromSystem(String channel, int tap) => ui.channelBuffers.push(
    channel,
    codec.encodeMethodCall(MethodCall('didReceiveNotificationResponse', tap)),
    (_) {},
  );

  Future<List<Object?>> takeAll(String name) async {
    final taken = <Object?>[];
    MethodChannel(name).setMethodCallHandler((call) async {
      taken.add(call.arguments);
      return null;
    });
    await Future<void>.delayed(Duration.zero);
    MethodChannel(name).setMethodCallHandler(null);

    return taken;
  }

  test('every notice tap from a slow start reaches the handler', () async {
    LaunchMessages.hold();
    for (var tap = 0; tap < 3; tap++) {
      sendFromSystem(LaunchMessages.notices, tap);
    }

    expect(await takeAll(LaunchMessages.notices), [0, 1, 2]);
  });

  test('without holding, Flutter keeps only the last one', () async {
    const other = 'ferret.test/unheld';
    for (var tap = 0; tap < 3; tap++) {
      sendFromSystem(other, tap);
    }

    expect(await takeAll(other), [2]);
  });
}
