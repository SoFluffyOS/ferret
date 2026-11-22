import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

DeviceStatus _pixel({bool reconnecting = false}) => DeviceStatus(
  TrustedDevice(
    id: 'abcdabcdabcdabcd',
    name: 'Pixel 7',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  ),
  null,
  isReconnecting: reconnecting,
);

void main() {
  testWidgets('How? says which feature it is for', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        const HealthRow(
          title: 'Messages',
          health: FeatureHealth(.off, reason: 'Off on Pixel 9', help: 'Steps'),
          howLabel: 'How?',
          fixLabel: 'Fix',
        ),
      ),
    );

    expect(find.bySemanticsLabel('How? Messages'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets("an Activity line's Open says which line it is on", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        ActivityTextAction(
          action: ActivityAction(label: 'Open', onPressed: () {}),
          filled: false,
          isShown: true,
          subject: 'IMG_2041.jpg from Pixel 9',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Open: IMG_2041.jpg from Pixel 9'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a health row is one stop: name, reason, then its state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        const HealthRow(
          title: 'Messages',
          health: FeatureHealth(.ok, reason: 'Texts and replies', help: ''),
          howLabel: 'How?',
          fixLabel: 'Fix',
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Messages')),
      isSemantics(label: 'Messages\nTexts and replies\nOK'),
    );
    semantics.dispose();
  });

  testWidgets("an Activity line's ✕ says which line it clears", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        ActivityIconAction(
          action: ActivityAction(
            label: 'Dismiss',
            icon: LucideIcons.x,
            onPressed: () {},
          ),
          reachesUp: false,
          subject: 'IMG_2041.jpg from Pixel 9',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Dismiss: IMG_2041.jpg from Pixel 9'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('each Set up on the offers says what it sets up', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        OfferRow(
          offer: FeatureOffer(
            title: 'Calls',
            description: "See who's calling.",
            actionLabel: 'Set up',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Set up: Calls'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Calls')),
      isSemantics(label: "Calls\nSee who's calling."),
    );
    semantics.dispose();
  });

  testWidgets("a device's page starts with one heading: name and status", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(DeviceHeader(status: _pixel(reconnecting: true))),
    );

    expect(
      tester.getSemantics(find.text('Pixel 7')),
      isSemantics(label: 'Pixel 7\nReconnecting…', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('a screen reader hears a device drop and come back, once each', (
    tester,
  ) async {
    Widget announcer(DeviceStatus status) => testApp(
      ConnectionAnnouncer(status: status, child: const SizedBox.shrink()),
    );

    await tester.pumpWidget(announcer(_pixel()));
    expect(tester.takeAnnouncements(), isEmpty);

    await tester.pumpWidget(announcer(_pixel(reconnecting: true)));
    expect(
      tester.takeAnnouncements().map((announcement) => announcement.message),
      ['Pixel 7: Reconnecting…'],
    );

    await tester.pumpWidget(announcer(_pixel(reconnecting: true)));
    expect(tester.takeAnnouncements(), isEmpty);

    await tester.pumpWidget(announcer(_pixel()));
    expect(
      tester.takeAnnouncements().map((announcement) => announcement.message),
      ['Pixel 7: Not connected'],
    );
  });
}
