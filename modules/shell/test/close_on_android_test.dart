import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/home_menu.dart';
import 'package:transport/transport.dart';

import 'test_app.dart';

void main() {
  late FerretEngine engine;

  setUp(() async {
    engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Pixel 7',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
      ),
      discovery: _SilentDiscovery(),
      port: 0,
    );
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PauseController(engine)),
          Provider.value(value: AppQuit(exitPlatform: () async {})),
        ],
        child: testApp(HomeMenu(onSettings: () {})),
      ),
    );
    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();
  }

  testWidgets('Android says Close Ferret: the service keeps running', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await openMenu(tester);

    expect(find.text('Close Ferret'), findsOneWidget);
    expect(find.text('Quit Ferret'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a computer keeps Quit Ferret', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await openMenu(tester);

    expect(find.text('Quit Ferret'), findsOneWidget);
    expect(find.text('Close Ferret'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
