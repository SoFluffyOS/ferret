import 'dart:async';
import 'dart:ui';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';

class _FakeTray implements DesktopTray {
  _FakeTray({required this.available});

  final bool available;
  final List<(String, List<TrayMenuItem>)> shown = [];
  final StreamController<void> clicks = .broadcast();
  final StreamController<String> picks = .broadcast();
  final StreamController<bool> changes = .broadcast();

  @override
  Future<bool> show({
    required String tooltip,
    required List<TrayMenuItem> items,
  }) async {
    shown.add((tooltip, items));
    return available;
  }

  @override
  Stream<void> get activations => clicks.stream;

  @override
  Stream<String> get selections => picks.stream;

  @override
  Stream<bool> get presence => changes.stream;

  @override
  Future<void> dispose() async {}
}

class _Notifier implements LocalNotifier {
  final List<LocalNotice> shown = [];

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(DesktopWindow.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  late FerretEngine engine;
  late EngineHost host;
  late PauseController pause;
  late List<MethodCall> calls;
  late _Notifier notifier;
  late FerretSystem system;

  setUp(() async {
    engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Laptop',
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      discovery: MemoryDiscoveryBus().join(),
      port: 0,
    );
    await engine.start();
    host = EngineHost(engine);
    pause = PauseController(engine);
    notifier = _Notifier();
    system = FerretSystem();
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'window.startedHidden' => true,
        _ => null,
      };
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    pause.dispose();
    await engine.stop();
  });

  Future<DesktopBinding> start(_FakeTray tray) async {
    final binding = DesktopBinding(
      host: host,
      pause: pause,
      settings: engine.settings,
      notifier: notifier,
      tray: tray,
      window: DesktopWindow.withChannel(channel),
      system: system,
      isDesktop: true,
      locale: const Locale('en'),
    );
    await binding.start();
    addTearDown(binding.dispose);
    return binding;
  }

  Future<void> fromRunner(String method) => messenger.handlePlatformMessage(
    DesktopWindow.channelName,
    codec.encodeMethodCall(MethodCall(method)),
    (_) {},
  );

  test('with a tray, closing hides Ferret and says so once', () async {
    final tray = _FakeTray(available: true);
    await start(tray);

    expect(calls.first.method, 'window.setHideOnClose');
    expect(calls.first.arguments, {'value': true});
    expect(calls.map((call) => call.method), isNot(contains('window.show')));
    expect(tray.shown.single.$2.map((item) => item.id), [
      'open',
      '',
      'clipboard',
      'pause',
      '',
      'quit',
    ]);

    await fromRunner('window.closedToTray');
    await fromRunner('window.closedToTray');
    await pumpEventQueue();

    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single.title, 'Ferret is still running');
  });

  test(
    'without a tray, closing quits, and autostart shows the window',
    () async {
      await start(_FakeTray(available: false));

      expect(calls.first.arguments, {'value': false});
      expect(calls.map((call) => call.method), contains('window.show'));
    },
  );

  test('a tray that turns up later lets closing hide Ferret, and one that '
      'leaves makes closing quit again', () async {
    final tray = _FakeTray(available: false);
    final binding = await start(tray);
    calls.clear();

    tray.changes.add(true);
    await pumpEventQueue();

    expect(binding.hasTray, isTrue);
    expect(TrayStatus.shows.value, isTrue);
    expect(
      calls
          .where((call) => call.method == 'window.setHideOnClose')
          .single
          .arguments,
      {'value': true},
    );
    expect(tray.shown, hasLength(2));

    calls.clear();
    tray.changes.add(false);
    await pumpEventQueue();

    expect(binding.hasTray, isFalse);
    expect(TrayStatus.shows.value, isFalse);
    expect(calls.single.arguments, {'value': false});
  });

  test('Send clipboard is greyed with nothing connected', () async {
    final tray = _FakeTray(available: true);
    await start(tray);

    final clipboard = tray.shown.single.$2.firstWhere(
      (item) => item.id == DesktopBinding.clipboardId,
    );
    expect(clipboard.enabled, isFalse);
  });

  test('the menu pauses, resumes, sends the clipboard and quits', () async {
    final tray = _FakeTray(available: true);
    await start(tray);
    final actions = system.actions.first;

    tray.picks.add(DesktopBinding.pauseId);
    await pumpEventQueue();
    expect(pause.isPaused, isTrue);
    expect(tray.shown.last.$2.map((item) => item.title), contains('Resume'));
    expect(tray.shown.last.$1, 'Ferret · Paused');

    tray.picks.add(DesktopBinding.pauseId);
    await pumpEventQueue();
    expect(pause.isPaused, isFalse);

    tray.picks.add(DesktopBinding.clipboardId);
    expect((await actions).id, SystemAction.clipboardSend);

    tray.picks.add(DesktopBinding.quitId);
    tray.clicks.add(null);
    await pumpEventQueue();
    expect(
      calls.map((call) => call.method),
      containsAll(['window.quit', 'window.toggle']),
    );
  });
}
