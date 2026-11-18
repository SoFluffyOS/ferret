import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

TrustedDevice _device({DateTime? lastSeen}) => TrustedDevice(
  id: 'abcdabcdabcdabcd',
  name: 'Pixel',
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
  lastSeen: lastSeen,
);

void main() {
  testWidgets('an offline device says when it was last seen and offers why', (
    tester,
  ) async {
    final lastSeen = DateTime.now().subtract(const Duration(minutes: 5));
    var askedWhy = false;

    await tester.pumpWidget(
      testApp(
        DeviceTile(
          status: DeviceStatus(_device(lastSeen: lastSeen), null),
          onWhy: () => askedWhy = true,
        ),
      ),
    );

    expect(find.text('Pixel'), findsOneWidget);
    expect(find.text('Last seen 5 min ago'), findsOneWidget);
    await tester.tap(find.text('Why?'));
    expect(askedWhy, isTrue);
  });

  testWidgets('the welcome card promises privacy and pairs in one tap', (
    tester,
  ) async {
    var paired = false;

    await tester.pumpWidget(testApp(EmptyDevices(onPair: () => paired = true)));

    expect(
      find.text('No account. No cloud. Stays on your network.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Pair a device'));
    expect(paired, isTrue);
  });
}
