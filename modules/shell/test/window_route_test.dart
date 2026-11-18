import 'dart:io' as io;
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
// The pigeon API is what a fake of the Mac side implements.
// ignore: implementation_imports
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';

class _FakeMenubarApi implements MenubarHostApi {
  _FakeMenubarApi(this.windowViewId);

  final int windowViewId;
  int popoverHidden = 0;
  int windowOpened = 0;

  @override
  Future<bool> isWindowSupported() async => true;

  @override
  Future<bool> isWindowOpen() async => false;

  @override
  Future<int> openWindow() async {
    windowOpened++;
    return windowViewId;
  }

  @override
  Future<void> setDockMode(MenubarDockMode mode) async {}

  @override
  Future<void> hidePopover() async => popoverHidden++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuietNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

void main() {
  late FerretEngine engine;
  late EngineHost host;
  late _FakeMenubarApi api;
  late FerretMenubar menubar;
  late AppViews views;
  late FeatureContext featureContext;
  late WindowNavRegistry registry;

  WindowNavViewModel view(GlobalKey<NavigatorState> navigatorKey) {
    final nav = WindowNavViewModel(
      host: host,
      navigatorKey: navigatorKey,
      pageFor: (destination) => DestinationPage(destination: destination),
    );
    addTearDown(nav.dispose);
    return nav;
  }

  Future<void> start(WidgetTester tester, {bool paired = true}) async {
    final started = await tester.runAsync(() async {
      final engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'MacBook Air',
          platform: .PLATFORM_MACOS,
          formFactor: .FORM_FACTOR_LAPTOP,
        ),
        features: const [],
        discovery: MemoryDiscoveryBus().join(),
        port: 0,
      );
      await engine.start();
      if (paired) {
        await engine.trustStore.save(
          TrustedDevice(
            id: 'a',
            name: 'Pixel 9',
            platform: .PLATFORM_ANDROID,
            formFactor: .FORM_FACTOR_PHONE,
            publicKey: Uint8List(32),
            pairedAt: DateTime(2026, 11, 1),
          ),
        );
      }

      return engine;
    });
    engine = started ?? (throw StateError('no engine'));
    host = EngineHost(engine);
    api = _FakeMenubarApi(tester.view.viewId);
    menubar = FerretMenubar(api: api);
    views = AppViews(menubar: menubar, settings: MemorySettingsStore());
    await views.start();
    featureContext = FeatureContext(
      engine: engine,
      navigatorKey: views.navigatorKey,
      notifier: _QuietNotifier(),
    );
    registry = WindowNavRegistry(featureContext, views: views);
    addTearDown(() async {
      views.dispose();
      host.dispose();
      await tester.runAsync(engine.stop);
    });
  }

  testWidgets('from the popover a section opens the window, right there', (
    tester,
  ) async {
    await start(tester);
    final popover = view(views.mainNavigatorKey);
    registry.add(popover);
    menubar.onPopoverVisibilityChanged(true);
    await tester.pump();

    await featureContext.openSection('a', 'messages');
    await tester.pump();

    expect(api.windowOpened, 1);
    expect(api.popoverHidden, 1);
    expect(popover.selection, const DeviceDestination('a'));

    final window = view(views.windowNavigatorKey);
    registry.add(window);
    expect(
      window.selection,
      const DeviceDestination('a', sectionId: 'messages'),
    );
  }, skip: !io.Platform.isMacOS);

  testWidgets('the window that opens for it starts on what was asked for', (
    tester,
  ) async {
    await start(tester);

    registry.open(const SettingsDestination());
    await tester.pump();
    final window = view(views.windowNavigatorKey);
    registry.add(window);

    expect(api.windowOpened, 1);
    expect(window.selection, const SettingsDestination());
  }, skip: !io.Platform.isMacOS);

  testWidgets('an open window just moves to it, and comes forward', (
    tester,
  ) async {
    await start(tester);
    await views.openWindow();
    final window = view(views.windowNavigatorKey);
    registry.add(window);

    registry.open(const ActivityDestination());
    await tester.pump();

    expect(api.windowOpened, 2);
  }, skip: !io.Platform.isMacOS);
}
