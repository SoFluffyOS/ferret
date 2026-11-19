import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

TrustedDevice _device(Platform platform, FormFactor formFactor) =>
    TrustedDevice(
      id: 'a',
      name: 'Pixel 7',
      platform: platform,
      formFactor: formFactor,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026, 11, 1),
    );

const _mac = LocalDevice(
  name: 'MacBook Air',
  platform: .PLATFORM_MACOS,
  formFactor: .FORM_FACTOR_LAPTOP,
);

void main() {
  test('an Android phone paired with a computer gets the webcam help', () {
    final pixel = _device(.PLATFORM_ANDROID, .FORM_FACTOR_PHONE);

    expect(WebcamHelpPage.fits(pixel, _mac), isTrue);
  });

  test('an iPhone, a tablet, or a phone looking at a phone does not', () {
    final pixel = _device(.PLATFORM_ANDROID, .FORM_FACTOR_PHONE);
    const otherPhone = LocalDevice(
      name: 'Galaxy',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
    );

    expect(
      WebcamHelpPage.fits(_device(.PLATFORM_IOS, .FORM_FACTOR_PHONE), _mac),
      isFalse,
    );
    expect(
      WebcamHelpPage.fits(
        _device(.PLATFORM_ANDROID, .FORM_FACTOR_TABLET),
        _mac,
      ),
      isFalse,
    );
    expect(WebcamHelpPage.fits(pixel, otherPhone), isFalse);
  });

  testWidgets('the steps name the phone and this Mac', (tester) async {
    await tester.pumpWidget(
      testApp(const WebcamHelpPage(deviceName: 'Pixel 7', here: 'mac')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pixel 7 as a webcam'), findsOneWidget);
    expect(
      find.textContaining('Plug Pixel 7 into this Mac with a USB cable.'),
      findsOneWidget,
    );
    expect(find.textContaining('Choose Webcam.'), findsOneWidget);
  });
}
