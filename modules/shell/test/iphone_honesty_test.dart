import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

TrustedDevice _iphone() => TrustedDevice(
  id: 'abcdabcdabcdabcd',
  name: 'iPhone',
  platform: .PLATFORM_IOS,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
  lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
);

void main() {
  testWidgets('an iPhone that is not connected says Ferret must be open', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(DeviceTile(status: DeviceStatus(_iphone(), null), onFix: () {})),
    );

    expect(find.text('Connects when Ferret is open on it'), findsOneWidget);
    expect(find.text('Last seen 5 min ago'), findsNothing);
    expect(find.text('Fix'), findsOneWidget);
  });

  testWidgets('on an iPhone the welcome asks to scan, without looking', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = .iOS;
    var scans = 0;

    await tester.pumpWidget(
      testApp(WelcomeEmpty(onPairWithCode: () => scans++, onCantSee: () {})),
    );
    await tester.pump(const Duration(seconds: 11));

    expect(find.text('Looking…'), findsNothing);
    expect(find.text("Can't see it?"), findsNothing);
    expect(
      find.text(
        'Install Ferret on your computer too, and open it. '
        'Then scan the code it shows.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Scan the code on your computer'));
    expect(scans, 1);
    debugDefaultTargetPlatformOverride = null;
  });
}
