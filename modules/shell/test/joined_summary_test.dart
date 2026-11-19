import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

TrustedDevice _device(String id, String name) => TrustedDevice(
  id: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
);

void main() {
  final pixel = _device('p', 'Pixel 7');
  final mac = _device('m', 'MacBook Pro');

  test('several joins read as one line with their introducer', () {
    final summary = JoinedSummary([
      DeviceJoined(device: _device('a', 'iPad'), introducer: pixel),
      DeviceJoined(device: _device('b', 'ThinkPad X1'), introducer: pixel),
      DeviceJoined(device: _device('c', 'DESKTOP-7Q2KD1'), introducer: pixel),
    ]);

    expect(summary.names, 'iPad, ThinkPad X1, DESKTOP-7Q2KD1');
    expect(summary.introducer, 'Pixel 7');
  });

  test('no introducer is named when several devices added them', () {
    final summary = JoinedSummary([
      DeviceJoined(device: _device('a', 'iPad'), introducer: pixel),
      DeviceJoined(device: _device('b', 'ThinkPad X1'), introducer: mac),
    ]);

    expect(summary.introducer, isNull);
  });
}
