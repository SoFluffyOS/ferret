import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

import 'test_app.dart';

final _now = DateTime(2026, 11, 19, 12);

DeviceStatus _device(
  String id,
  String name, {
  required int pairedDaysAgo,
  int? seenDaysAgo,
  Platform platform = .PLATFORM_ANDROID,
  bool connected = false,
}) => DeviceStatus(
  TrustedDevice(
    id: id,
    name: name,
    platform: platform,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: _now.subtract(Duration(days: pairedDaysAgo)),
    lastSeen: switch (seenDaysAgo) {
      final days? => _now.subtract(Duration(days: days)),
      null => null,
    },
  ),
  null,
  isReconnecting: connected,
);

List<(String, String)> _pairs(List<Successor> found) => [
  for (final successor in found) (successor.replacement.id, successor.old.id),
];

void main() {
  late MemorySettingsStore settings;

  setUp(() => settings = MemorySettingsStore());

  group('a new phone with an old one\'s name', () {
    test('is offered as its replacement', () {
      final found = DeviceSuccessors(settings).find([
        _device('old', 'Pixel 7', pairedDaysAgo: 300, seenDaysAgo: 120),
        _device('new', 'pixel 7 ', pairedDaysAgo: 1, seenDaysAgo: 0),
        _device('mac', 'MacBook', pairedDaysAgo: 300, seenDaysAgo: 0),
      ], now: _now);

      expect(_pairs(found), [('new', 'old')]);
    });

    test('not when the old one was seen after it paired', () {
      final found = DeviceSuccessors(settings).find([
        _device('old', 'Pixel 7', pairedDaysAgo: 300, seenDaysAgo: 0),
        _device('new', 'Pixel 7', pairedDaysAgo: 2),
      ], now: _now);

      expect(found, isEmpty);
    });

    test('not when the old one is connected right now', () {
      final found = DeviceSuccessors(settings).find([
        _device('old', 'Pixel 7', pairedDaysAgo: 300, connected: true),
        _device('new', 'Pixel 7', pairedDaysAgo: 2),
      ], now: _now);

      expect(found, isEmpty);
    });

    test('not for another platform, or after two weeks', () {
      final found = DeviceSuccessors(settings).find([
        _device('old', 'Pixel 7', pairedDaysAgo: 300, seenDaysAgo: 200),
        _device('ios', 'Pixel 7', pairedDaysAgo: 1, platform: .PLATFORM_IOS),
        _device('late', 'Pixel 7', pairedDaysAgo: 20),
      ], now: _now);

      expect(found, isEmpty);
    });

    test('keep both is remembered', () async {
      final successors = DeviceSuccessors(settings);
      final devices = [
        _device('old', 'Pixel 7', pairedDaysAgo: 300, seenDaysAgo: 120),
        _device('new', 'Pixel 7', pairedDaysAgo: 1),
      ];

      await successors.keepBoth('new');

      expect(successors.find(devices, now: _now), isEmpty);
    });

    test('each old phone goes to its newest namesake once', () {
      final found = DeviceSuccessors(settings).find([
        _device('oldest', 'Pixel 7', pairedDaysAgo: 600, seenDaysAgo: 400),
        _device('old', 'Pixel 7', pairedDaysAgo: 300, seenDaysAgo: 120),
        _device('new', 'Pixel 7', pairedDaysAgo: 1),
      ], now: _now);

      expect(_pairs(found), [('new', 'old')]);
    });
  });

  test('the new phone inherits the pin and last use', () async {
    final preferences = DevicePreferences(settings);
    await preferences.setPinned('old', pinned: true);
    await preferences.markUsed('old', at: _now);

    await preferences.inherit('old', newId: 'new');

    expect(preferences.pinned, {'new'});
    expect(preferences.lastUsed('new'), _now);
    expect(preferences.lastUsed('old'), isNull);
  });

  group('what\'s new', () {
    test('a fresh install has nothing new', () {
      final whatsNew = WhatsNew(settings);

      expect(
        whatsNew.takeUpdate(appVersion: '0.2.0', hasPaired: false),
        isNull,
      );
      expect(settings.get<String>(WhatsNew.seenVersionKey), '0.2.0');
    });

    test('an install from before the line existed hears it once', () {
      final whatsNew = WhatsNew(settings);

      expect(
        whatsNew.takeUpdate(appVersion: '0.2.0', hasPaired: true),
        '0.2.0',
      );
      expect(whatsNew.takeUpdate(appVersion: '0.2.0', hasPaired: true), isNull);
    });

    test('each update is told once, then never again', () async {
      await settings.set(WhatsNew.seenVersionKey, '0.1.0');
      final whatsNew = WhatsNew(settings);

      expect(
        whatsNew.takeUpdate(appVersion: '0.3.0', hasPaired: false),
        '0.3.0',
      );
      expect(whatsNew.takeUpdate(appVersion: '0.3.0', hasPaired: true), isNull);
    });

    test('a build without a version says nothing', () {
      expect(
        WhatsNew(settings).takeUpdate(appVersion: '', hasPaired: true),
        isNull,
      );
    });

    test('the notes link points at the release', () {
      expect(
        WhatsNew.notesFor('0.3.0').toString(),
        'https://github.com/simonpham/ferret/releases/tag/v0.3.0',
      );
    });
  });

  group('a version mismatch', () {
    testWidgets('names the older device and its version', (tester) async {
      await tester.pumpWidget(
        testApp(
          const UpdateNeededCard(
            mismatch: VersionMismatch(
              update: .otherDevice,
              remoteProtocol: 1,
              remoteAppVersion: '0.1.0',
            ),
            deviceName: 'Pixel 7',
            here: 'this Mac',
          ),
        ),
      );

      expect(find.text('Update Ferret on Pixel 7'), findsOneWidget);
      expect(find.textContaining('older Ferret (0.1.0)'), findsOneWidget);
      expect(find.text('Get the update'), findsNothing);
    });

    testWidgets('offers the update when this device is behind', (
      tester,
    ) async {
      var opened = false;
      await tester.pumpWidget(
        testApp(
          UpdateNeededCard(
            mismatch: const VersionMismatch(
              update: .thisDevice,
              remoteProtocol: 2,
            ),
            deviceName: 'Galaxy S24',
            here: 'this Mac',
            onGetUpdate: () => opened = true,
          ),
        ),
      );

      expect(find.text('Update Ferret on this Mac'), findsOneWidget);
      await tester.tap(find.text('Get the update'));
      expect(opened, isTrue);
    });
  });
}
