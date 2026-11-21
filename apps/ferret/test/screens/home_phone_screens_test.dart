// Home on an Android phone paired with a Mac and an iPhone: the iPhone row
// with and without Fix, the Stay connected card next to Do more with the
// Quick Settings tile offer, and Do more with only an iPhone paired. Renders into temp/screens as
// `home_phone_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/home_phone_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:clipboard/clipboard.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

const _iphoneId = 'a1b2c3d4e5f60718';

/// Android 13+ that still optimizes Ferret's battery use.
class _Pixel extends Fake implements FerretSystem {
  @override
  bool get isAndroid => true;

  @override
  Stream<SystemAction> get actions => const Stream.empty();

  @override
  Future<bool> areNotificationsAllowed() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => false;

  @override
  Future<bool> isBackgroundRestricted() async => false;

  @override
  Future<DeviceMaker> deviceMaker() async => .other;

  @override
  Future<int> serviceStopsToday({DateTime? now}) async => 0;

  @override
  Future<bool> canRequestAddTile() async => true;
}

/// A Pixel on Android 17 once Ferret targets it, before the local network
/// is allowed.
class _Android17 extends Fake implements FerretSystem {
  _Android17(this.access);

  final LocalNetworkAccess access;

  @override
  bool get isAndroid => true;

  @override
  Future<LocalNetworkAccess> localNetworkAccess() async => access;
}

List<FeatureUi> _features() => [
  for (final feature in phoneFeatures())
    switch (feature) {
      ClipboardFeatureUi() => ClipboardFeatureUi(system: _Pixel()),
      _ => feature,
    },
];

typedef _Script = Future<void> Function(WidgetTester tester, ScreenRig rig);

Future<void> _macAndIphone(WidgetTester tester, ScreenRig rig) async {
  await rig.pairConnectedComputer(
    tester,
    computerFeatures: appFeatures(),
    name: 'Simon’s MacBook Pro',
  );
  await rig.addOfflinePhone(
    tester,
    name: 'iPhone 12 mini',
    id: _iphoneId,
    platform: .PLATFORM_IOS,
  );
  await rig.settle(tester);
}

final _screens = <String, _Script>{
  'iphone_waiting': (tester, rig) async {
    await _macAndIphone(tester, rig);
    expect(find.text('Fix'), findsNothing);
  },
  'iphone_heard': (tester, rig) async {
    await _macAndIphone(tester, rig);
    await rig.hearPaired(tester, id: _iphoneId, name: 'iPhone 12 mini');
    expect(find.text('Fix'), findsOneWidget);
  },
  'stay_and_offers': (tester, rig) async {
    await rig.pairConnectedComputer(
      tester,
      computerFeatures: appFeatures(),
      name: 'Simon’s MacBook Pro',
    );
    await rig.open(
      tester,
      FerretPage(
        title: 'Ferret',
        backLabel: 'Back',
        children: [
          StayConnectedCard(system: _Pixel()),
          const OffersCard(),
        ],
      ),
    );
    expect(find.text('Add tile'), findsWidgets);
    expect(find.text('Calls'), findsWidgets);
  },
  // Calls, texts and notifications promise a computer, so a phone paired
  // only with an iPhone isn't offered them.
  'iphone_only': (tester, rig) async {
    await rig.addOfflinePhone(
      tester,
      name: 'iPhone 12 mini',
      id: _iphoneId,
      platform: .PLATFORM_IOS,
    );
    await rig.settle(tester);
    expect(find.text('Calls'), findsNothing);
    expect(find.text('Messages'), findsNothing);
    expect(find.text('Notifications'), findsNothing);
  },
  'local_network_ask': (tester, rig) async {
    await rig.open(
      tester,
      FerretPage(
        title: 'Ferret',
        backLabel: 'Back',
        children: [LocalNetworkCard(system: _Android17(.notGranted))],
      ),
    );
    expect(find.text('Allow'), findsOneWidget);
  },
  'local_network_blocked': (tester, rig) async {
    await rig.open(
      tester,
      FerretPage(
        title: 'Ferret',
        backLabel: 'Back',
        children: [LocalNetworkCard(system: _Android17(.blocked))],
      ),
    );
    expect(find.text('Open Settings'), findsOneWidget);
  },
  'local_network_doctor': (tester, rig) async {
    await rig.open(
      tester,
      DoctorPage(
        doctorFor: (engine) => ConnectionDoctor(
          engine,
          isWindows: false,
          isLinux: false,
          localNetwork: () async => .notGranted,
        ),
      ),
    );
    expect(find.text('Allow on this Wi-Fi'), findsOneWidget);
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('home_phone $name ${brightness.name}', (tester) async {
        setScreen(tester, phone, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = phone.platform;
        try {
          final rig = await ScreenRig.create(
            tester,
            features: _features(),
            name: 'Pixel 7',
            tipsDone: true,
            asPhone: true,
          );
          await rig.show(tester);
          await script(tester, rig);
          await rig.capture(tester, 'home_phone_$name', phone, brightness);
          await rig.dispose(tester);
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
