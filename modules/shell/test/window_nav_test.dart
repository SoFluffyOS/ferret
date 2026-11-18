import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';

class _NoFeature extends Feature {
  @override
  String get id => 'texts';

  @override
  Future<Null> onEnvelope(Session session, Envelope envelope) async => null;
}

/// A feature with one page per device, and a button that opens it.
class _TextsUi extends FeatureUi {
  @override
  String get featureId => 'texts';

  @override
  final Feature feature = _NoFeature();

  @override
  String title(BuildContext context) => 'Texts';

  @override
  IconData get icon => LucideIcons.messageSquare;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => [
    FeatureSection(
      id: 'texts',
      title: 'Texts',
      icon: icon,
      order: 10,
      badge: 2,
      builder: (_) => Text('Texts of ${device.device.name}'),
    ),
  ];
}

class _QuietNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

TrustedDevice _device(String id, String name) => TrustedDevice(
  id: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026, 11, 1),
);

Future<FerretEngine> _engine({
  SettingsStore? settings,
  List<Feature> features = const [],
}) async {
  final engine = await FerretEngine.create(
    secrets: MemorySecretStore(),
    settings: settings ?? MemorySettingsStore(),
    device: const LocalDevice(
      name: 'MacBook Air',
      platform: .PLATFORM_MACOS,
      formFactor: .FORM_FACTOR_LAPTOP,
    ),
    features: features,
    discovery: MemoryDiscoveryBus().join(),
    port: 0,
  );
  await engine.start();
  return engine;
}

WindowNavViewModel _nav(EngineHost host, {SettingsStore? settings}) =>
    WindowNavViewModel(
      host: host,
      navigatorKey: GlobalKey<NavigatorState>(),
      settings: settings,
      pageFor: (destination) => DestinationPage(destination: destination),
    );

void main() {
  setUpAll(initializeDateFormatting);

  group('WindowNavViewModel', () {
    late FerretEngine engine;
    late EngineHost host;

    setUp(() async {
      engine = await _engine();
      host = EngineHost(engine);
    });

    tearDown(() async {
      host.dispose();
      await engine.stop();
    });

    test('nothing is selected while nothing is paired', () {
      final nav = _nav(host);
      addTearDown(nav.dispose);

      expect(nav.selection, isNull);
      expect(nav.selectedDeviceId, isNull);
    });

    test('the first device opens by itself, on its Overview', () async {
      await engine.trustStore.save(_device('b', 'Pixel 9'));
      await engine.trustStore.save(_device('a', 'iPad'));
      final nav = _nav(host);
      addTearDown(nav.dispose);

      expect(nav.selection, const DeviceDestination('a'));
    });

    test('a selection is kept, and a new window opens on it', () async {
      final settings = MemorySettingsStore();
      await engine.trustStore.save(_device('a', 'iPad'));
      await engine.trustStore.save(_device('b', 'Pixel 9'));
      final nav = _nav(host, settings: settings);
      addTearDown(nav.dispose);

      nav.select(const DeviceDestination('b', sectionId: 'texts'));
      final reopened = _nav(host, settings: settings);
      addTearDown(reopened.dispose);

      expect(
        reopened.selection,
        const DeviceDestination('b', sectionId: 'texts'),
      );
      expect(reopened.selectedDeviceId, 'b');
    });

    test('forgetting the selected device moves on to another', () async {
      await engine.trustStore.save(_device('a', 'iPad'));
      await engine.trustStore.save(_device('b', 'Pixel 9'));
      final nav = _nav(host)..select(const DeviceDestination('b'));
      addTearDown(nav.dispose);

      await engine.unpair('b');

      expect(nav.selection, const DeviceDestination('a'));
    });

    test('stepping through devices goes around the ends', () async {
      await engine.trustStore.save(_device('a', 'iPad'));
      await engine.trustStore.save(_device('b', 'Pixel 9'));
      final nav = _nav(host);
      addTearDown(nav.dispose);

      nav.selectDeviceBy(1);
      expect(nav.selectedDeviceId, 'b');

      nav.selectDeviceBy(1);
      expect(nav.selectedDeviceId, 'a');

      nav.selectDeviceBy(-1);
      expect(nav.selectedDeviceId, 'b');
    });

    test('Activity and Settings are places of their own', () async {
      await engine.trustStore.save(_device('a', 'iPad'));
      final nav = _nav(host);
      addTearDown(nav.dispose);
      var changes = 0;
      nav.addListener(() => changes++);

      nav.select(const SettingsDestination());
      nav.select(const SettingsDestination());

      expect(nav.selection, isA<SettingsDestination>());
      expect(nav.selectedDeviceId, isNull);
      expect(changes, 1);
    });

    test('hiding the device list is remembered', () {
      final settings = MemorySettingsStore();
      final nav = _nav(host, settings: settings);
      addTearDown(nav.dispose);

      nav.toggleSidebar();
      final reopened = _nav(host, settings: settings);
      addTearDown(reopened.dispose);

      expect(reopened.isSidebarHidden, isTrue);
    });
  });

  test('a destination reads back what it stored', () {
    for (final destination in const <WindowDestination>[
      DeviceDestination('a1b2'),
      DeviceDestination('a1b2', sectionId: 'messages'),
    ]) {
      expect(WindowDestination.parse(destination.stored), destination);
    }

    expect(
      WindowDestination.parse(const ActivityDestination().stored),
      isA<ActivityDestination>(),
    );
    expect(
      WindowDestination.parse(const SettingsDestination().stored),
      isA<SettingsDestination>(),
    );
    expect(WindowDestination.parse('nonsense'), isNull);
    expect(WindowDestination.parse(null), isNull);
  });

  group('sections', () {
    late FerretEngine engine;
    late FeatureContext featureContext;
    late Widget app;

    Future<void> start(WidgetTester tester, Size size) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);

      final features = <FeatureUi>[_TextsUi()];
      final started = await tester.runAsync(() async {
        final engine = await _engine(
          features: [for (final feature in features) feature.feature],
        );
        await engine.trustStore.save(_device('a', 'Pixel 9'));
        await engine.settings.set(TipsFrame.copyDoneKey, true);
        await engine.settings.set(TipsFrame.dragDoneKey, true);
        return engine;
      });
      engine = started ?? (throw StateError('no engine'));
      featureContext = FeatureContext(
        engine: engine,
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: _QuietNotifier(),
      );
      final host = EngineHost(engine);
      final pause = PauseController(engine);
      app = FerretApp(
        host: host,
        pause: pause,
        features: features,
        featureContext: featureContext,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        pause.dispose();
        host.dispose();
        await tester.runAsync(engine.stop);
      });

      await tester.pumpWidget(app);
      await tester.pump();
    }

    testWidgets('a window lists a device with its sections, and shows the '
        'one that is picked', (tester) async {
      await start(tester, const Size(1000, 720));

      expect(find.byType(SidebarFrame), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(DevicePage), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);

      await tester.tap(find.widgetWithText(SidebarRow, 'Texts'));
      await tester.pump();

      expect(find.text('Texts of Pixel 9'), findsOneWidget);
      expect(find.byType(DevicePage), findsNothing);
      expect(
        tester.widget<SidebarRow>(find.widgetWithText(SidebarRow, 'Texts')),
        isA<SidebarRow>().having((row) => row.isSelected, 'isSelected', true),
      );
    });

    testWidgets('a feature opening its section selects it in a window', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));

      unawaited(featureContext.openSection('a', 'texts'));
      await tester.pump();

      expect(find.text('Texts of Pixel 9'), findsOneWidget);
      expect(featureContext.navigatorKey.currentState?.canPop(), isFalse);
    });

    testWidgets('on a small view the same section is pushed over Home', (
      tester,
    ) async {
      await start(tester, const Size(380, 560));

      expect(find.byType(SidebarFrame), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);

      unawaited(featureContext.openSection('a', 'texts'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Texts of Pixel 9'), findsOneWidget);
      expect(featureContext.navigatorKey.currentState?.canPop(), isTrue);
    });

    testWidgets('narrowing a window keeps the page opened on top', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));
      unawaited(
        featureContext.push<void>(const Text('A page on top')),
      );
      await tester.pump();
      await tester.pump();

      tester.view.physicalSize = const Size(380, 560);
      await tester.pump();
      await tester.pump();

      expect(find.byType(SidebarFrame), findsNothing);
      expect(find.text('A page on top'), findsOneWidget);
      expect(featureContext.navigatorKey.currentState?.canPop(), isTrue);
    });

    testWidgets('keys open sections, Settings and hide the device list', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));

      Future<void> press(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();
      }

      await press(LogicalKeyboardKey.digit2);
      expect(find.text('Texts of Pixel 9'), findsOneWidget);

      await press(LogicalKeyboardKey.digit1);
      expect(find.byType(DevicePage), findsOneWidget);

      await press(LogicalKeyboardKey.comma);
      expect(find.byType(SettingsPage), findsOneWidget);

      await press(LogicalKeyboardKey.keyB);
      expect(find.byType(SidebarFrame), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('a section that is gone falls back to the Overview', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));

      unawaited(featureContext.openSection('a', 'gone'));
      await tester.pump();

      expect(find.byType(DevicePage), findsOneWidget);
    });
  });
}
