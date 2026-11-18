import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('an offline device says when it was last seen and offers Fix', (
    tester,
  ) async {
    final lastSeen = DateTime.now().subtract(const Duration(minutes: 5));
    var fixes = 0;

    await tester.pumpWidget(
      testApp(
        DeviceTile(
          status: DeviceStatus(_device(lastSeen: lastSeen), null),
          actions: [
            FeatureAction(
              label: 'Send files',
              icon: LucideIcons.upload,
              onPressed: () {},
            ),
          ],
          onFix: () => fixes++,
        ),
      ),
    );

    expect(find.text('Pixel'), findsOneWidget);
    expect(find.text('Last seen 5 min ago'), findsOneWidget);
    expect(find.text('Send files'), findsNothing);
    await tester.tap(find.text('Fix'));
    expect(fixes, 1);
  });

  testWidgets('a connected device has its actions on the row, one primary', (
    tester,
  ) async {
    final pressed = <String>[];
    FeatureAction action(String label) => FeatureAction(
      label: label,
      icon: LucideIcons.upload,
      onPressed: () => pressed.add(label),
    );

    await tester.pumpWidget(
      testApp(
        DeviceTile(
          status: DeviceStatus(_device(), _FakeSession()),
          actions: [
            action('Send files'),
            action('Send clipboard'),
            action('Ring'),
          ],
          hasPrimary: true,
          onFix: () {},
        ),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Fix'), findsNothing);
    await tester.tap(find.text('Send clipboard'));
    await tester.tap(find.text('Ring'));
    expect(pressed, ['Send clipboard', 'Ring']);

    final primaries = tester
        .widgetList<RowActionButton>(find.byType(RowActionButton))
        .where((button) => button.isPrimary);
    expect(primaries.single.label, 'Send files');
  });

  testWidgets('a feature that stopped working shows on the device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        DeviceTile(
          status: DeviceStatus(_device(), _FakeSession()),
          attention: 'Notifications',
        ),
      ),
    );

    expect(
      find.text('Connected · Notifications: needs attention'),
      findsOneWidget,
    );
  });

  testWidgets('the welcome promises privacy and stops looking after a while', (
    tester,
  ) async {
    var codes = 0;
    var cantSee = 0;

    await tester.pumpWidget(
      testApp(
        WelcomeEmpty(
          onPairWithCode: () => codes++,
          onCantSee: () => cantSee++,
        ),
      ),
    );

    expect(find.text('Your devices, working together'), findsOneWidget);
    expect(
      find.text('No account. No cloud. Stays on your network.'),
      findsOneWidget,
    );
    expect(find.text('Looking…'), findsOneWidget);
    expect(find.text("Can't see it?"), findsNothing);

    await tester.pump(const Duration(seconds: 11));
    await tester.tap(find.text("Can't see it?"));
    await tester.tap(find.text('Pair with a QR code'));

    expect(find.text('Looking…'), findsNothing);
    expect((codes, cantSee), (1, 1));
  });

  testWidgets('an activity line shows when it happened and what to do', (
    tester,
  ) async {
    var copied = 0;
    final now = DateTime(2026, 11, 18, 12);

    await tester.pumpWidget(
      testApp(
        ActivityRow(
          now: now,
          item: ActivityItem(
            id: 'clip',
            icon: LucideIcons.clipboard,
            title: 'Copied on Pixel',
            detail: '“Meet at 6”',
            at: now.subtract(const Duration(minutes: 2)),
            actions: [
              ActivityAction(label: 'Copy', onPressed: () => copied++),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Copied on Pixel'), findsOneWidget);
    expect(find.text('“Meet at 6”'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    expect(copied, 1);
  });

  testWidgets('a pinned line shows its controls instead of a time', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 18, 12);

    await tester.pumpWidget(
      testApp(
        ActivityRow(
          now: now,
          item: ActivityItem(
            id: 'media',
            icon: LucideIcons.music,
            title: 'Lo-fi mix · Pixel',
            at: now,
            pinned: true,
            actions: [
              ActivityAction(
                label: 'Pause',
                icon: LucideIcons.pause,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('now'), findsNothing);
    expect(find.byIcon(LucideIcons.pause), findsOneWidget);
  });
}
