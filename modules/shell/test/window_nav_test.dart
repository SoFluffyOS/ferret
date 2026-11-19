import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';
import 'package:provider/provider.dart';
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
  /// What it found near that isn't paired, by name.
  final List<String> near = [];
  final List<String> shown = [];
  final ChangeNotifier changes = ChangeNotifier();

  @override
  Listenable get uiChanges => changes;

  @override
  List<FeatureNearbyRow> nearbyRows(
    BuildContext context,
    FeatureContext feature,
  ) => [
    for (final name in near)
      FeatureNearbyRow(
        id: 'texts.$name',
        title: name,
        detail: 'Cable',
        icon: LucideIcons.smartphone,
        actionLabel: 'Show screen',
        onAction: () => shown.add(name),
      ),
  ];

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
    late _TextsUi texts;

    Future<void> start(WidgetTester tester, Size size) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);

      texts = _TextsUi();
      final features = <FeatureUi>[texts];
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

    testWidgets('what a feature found near sits under Nearby in the device '
        'list, with its one action', (tester) async {
      await start(tester, const Size(1000, 720));

      expect(find.text('Nearby'), findsNothing);

      texts.near.add('Old tablet');
      texts.changes.notifyListeners();
      await tester.pump();

      expect(find.text('Nearby'), findsOneWidget);
      final row = find.widgetWithText(SidebarRow, 'Old tablet');
      expect(
        find.descendant(of: row, matching: find.text('Show screen')),
        findsOneWidget,
      );

      await tester.tap(row);
      expect(texts.shown, ['Old tablet']);
    });

    testWidgets('Nearby in the device list folds away, and stays folded', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));
      texts.near.add('Old tablet');
      texts.changes.notifyListeners();
      await tester.pump();

      await tester.tap(find.text('Nearby'));
      await tester.pump();

      expect(find.text('Nearby'), findsOneWidget);
      expect(find.widgetWithText(SidebarRow, 'Old tablet'), findsNothing);
      expect(
        engine.settings.get<bool>(WindowNavViewModel.nearbyCollapsedKey),
        isTrue,
      );

      await tester.tap(find.text('Nearby'));
      await tester.pump();

      expect(find.widgetWithText(SidebarRow, 'Old tablet'), findsOneWidget);
    });

    testWidgets('the pane has a toolbar that names it and hides the list', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));

      expect(
        find.descendant(
          of: find.byType(PaneToolbarFrame),
          matching: find.textContaining('Overview'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(LucideIcons.panelLeftClose));
      await tester.pumpAndSettle();

      expect(find.byType(SidebarFrame), findsNothing);

      await tester.tap(find.byIcon(LucideIcons.panelLeftOpen));
      await tester.pumpAndSettle();

      expect(find.byType(SidebarFrame), findsOneWidget);
    });

    testWidgets('on a small view it is a line under Nearby on Home', (
      tester,
    ) async {
      await start(tester, const Size(380, 900));
      texts.near.add('Old tablet');
      texts.changes.notifyListeners();
      await tester.pump();

      expect(find.text('Nearby'), findsOneWidget);
      final tile = find.widgetWithText(NearbyFeatureTile, 'Old tablet');
      expect(
        find.descendant(of: tile, matching: find.text('Cable')),
        findsOneWidget,
      );

      await tester.tap(find.text('Show screen'));
      expect(texts.shown, ['Old tablet']);
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

      await press(LogicalKeyboardKey.digit2);
      expect(find.text('Texts of Pixel 9'), findsOneWidget);

      await press(LogicalKeyboardKey.comma);
      await press(LogicalKeyboardKey.keyB);
      await tester.pumpAndSettle();
      expect(find.byType(SidebarFrame), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Settings keeps its list next to the row that is open', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));

      await tester.tap(find.widgetWithText(SidebarRow, 'Settings'));
      await tester.pump();

      expect(find.byType(SettingsSplitFrame), findsOneWidget);
      expect(find.byType(ThisDeviceSettingsPage), findsOneWidget);

      await tester.tap(find.widgetWithText(NavRow, 'Advanced'));
      await tester.pump();

      expect(find.byType(AdvancedSettingsPage), findsOneWidget);
      expect(find.byType(ThisDeviceSettingsPage), findsNothing);
      expect(
        find.widgetWithText(NavRow, 'About · Privacy'),
        findsOneWidget,
      );
      expect(
        tester.widget<NavRow>(find.widgetWithText(NavRow, 'Advanced')),
        isA<NavRow>().having((row) => row.isSelected, 'isSelected', true),
      );
    });

    testWidgets('in a narrow window Settings is one list that opens pages', (
      tester,
    ) async {
      await start(tester, const Size(700, 720));

      await tester.tap(find.widgetWithText(SidebarRow, 'Settings'));
      await tester.pump();

      expect(find.byType(SettingsSplitFrame), findsNothing);
      expect(find.byType(NavRow), findsWidgets);
    });

    testWidgets('a right-click on a device offers its fix and forgetting it', (
      tester,
    ) async {
      await start(tester, const Size(1000, 720));
      await tester.tap(find.widgetWithText(SidebarRow, 'Texts'));
      await tester.pump();

      await tester.tap(
        find.widgetWithText(SidebarDeviceRow, 'Pixel 9'),
        buttons: kSecondaryButton,
      );
      await tester.pump();

      expect(find.text('Fix Connection…'), findsOneWidget);

      await tester.tap(find.text('Forget This Device…'));
      await tester.pump();

      expect(find.byType(DevicePage), findsOneWidget);
      expect(find.text('Forget This Device…'), findsNothing);
    });

    testWidgets('an offline device keeps its section, under a line that says '
        'so', (tester) async {
      await start(tester, const Size(1000, 720));

      await tester.tap(find.widgetWithText(SidebarRow, 'Texts'));
      await tester.pump();

      expect(find.text('Texts of Pixel 9'), findsOneWidget);
      expect(find.byType(OfflineLine), findsOneWidget);
      expect(find.textContaining('Pixel 9 is offline.'), findsOneWidget);

      await tester.tap(find.text('Fix connection'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DoctorPage), findsOneWidget);
    });

    testWidgets('files dragged over an offline device say it is offline, '
        'and the page stays', (tester) async {
      await start(tester, const Size(1000, 720));
      final drop = tester
          .element(find.byType(SidebarFrame))
          .read<OsDropViewModel>();

      drop.enter(tester.getCenter(find.byType(SidebarDeviceRow)));
      await tester.pump();

      expect(find.byType(DropTargetTile), findsNothing);
      expect(find.byType(DevicePage), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);

      drop.move(tester.getCenter(find.byType(DevicePage)));
      await tester.pump();

      expect(find.text('Pixel 9 is offline'), findsOneWidget);

      drop.cancel();
      await tester.pump();

      expect(find.text('Pixel 9 is offline'), findsNothing);
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
