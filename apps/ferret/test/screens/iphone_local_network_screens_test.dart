// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
// ignore_for_file: depend_on_referenced_packages

import 'package:core/core.dart';
import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

import 'support/ios_features.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

/// The iPhone's Local Network question in context: why Ferret looks,
/// before iOS asks, and what Nearby and Fix connection say after a no.
final _screens =
    <String, (bool denied, Future<void> Function(WidgetTester, ScreenRig))>{
      'welcome': (false, (tester, rig) async {}),
      'scan_dialog': (
        false,
        (tester, rig) async {
          await rig.tapText(tester, 'Scan the code');
        },
      ),
      'pair': (
        false,
        (tester, rig) async {
          await rig.open(tester, const PairPage());
        },
      ),
      'doctor': (
        false,
        (tester, rig) async {
          await rig.open(tester, const DoctorPage());
        },
      ),
      'denied': (true, (tester, rig) async {}),
      'denied_pair': (
        true,
        (tester, rig) async {
          await rig.open(tester, const PairPage());
        },
      ),
      'denied_doctor': (
        true,
        (tester, rig) async {
          await rig.open(tester, const DoctorPage());
        },
      ),
    };

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: (denied, script)) in _screens.entries) {
    testWidgets('iphone_local_network $name', (tester) async {
      setScreen(tester, iphone, .light);
      mockPlugins(tester);
      debugDisableShadows = false;
      debugDefaultTargetPlatformOverride = iphone.platform;
      try {
        final rig = await ScreenRig.create(
          tester,
          features: iosFeatures(),
          tipsDone: true,
          asIphone: true,
        );
        final ask = LocalNetworkAsk(
          settings: MemorySettingsStore(),
          held: HeldDiscovery(_Quiet()),
          hasDevices: () => false,
          probe: _Probe(denied),
        );
        if (denied) {
          await tester.runAsync(ask.allow);
        }

        rig.featureContext.localNetwork = ask;
        await rig.show(tester);
        await script(tester, rig);
        await rig.capture(tester, 'iphone_local_network_$name', iphone, .light);
        await rig.dispose(tester);
      } finally {
        debugDisableShadows = true;
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}

class _Probe extends LocalNetworkProbe {
  const _Probe(this.denied) : super(isIos: true);

  final bool denied;

  @override
  Future<LocalNetworkState> check() async => switch (denied) {
    true => .denied,
    false => .allowed,
  };
}

class _Quiet implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
