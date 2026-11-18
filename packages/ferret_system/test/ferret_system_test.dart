import 'package:ferret_system/ferret_system.dart';
import 'package:ferret_system/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('on Android', () {
    late _FakeApi api;
    late FerretSystem system;

    setUp(() {
      api = _FakeApi();
      system = FerretSystem.forTesting(api: api, platform: .android);
    });

    test('actions reach Dart and native is told once Dart listens', () async {
      final received = <SystemAction>[];
      final first = system.actions.listen(received.add);
      final second = system.actions.listen((_) {});

      system.onAction(
        SystemActionMessage(id: 'clipboard.send', data: {'text': 'hello'}),
      );
      await pumpEventQueue();

      expect(
        api.calls.where((call) => call == 'listenForActions'),
        hasLength(1),
      );
      expect(received, [
        const SystemAction(SystemAction.clipboardSend, {'text': 'hello'}),
      ]);
      await first.cancel();
      await second.cancel();
    });

    test('network watching follows listeners', () async {
      final changes = <NetworkChange>[];
      final subscription = system.networkChanges.listen(changes.add);
      system
        ..onNetworkChange(.wake)
        ..onNetworkChange(.available);
      await pumpEventQueue();
      await subscription.cancel();

      expect(changes, [NetworkChange.wake, NetworkChange.available]);
      expect(api.watching, [true, false]);
    });

    test('pauses from the notification arrive with their end time', () async {
      final until = DateTime(2026, 11, 18, 15, 30);
      final pauses = <PauseState>[];
      final subscription = system.pauseChanges.listen(pauses.add);

      system
        ..onPauseChanged(
          PauseMessage(paused: true, untilMs: until.millisecondsSinceEpoch),
        )
        ..onPauseChanged(PauseMessage(paused: false, untilMs: 5));
      await pumpEventQueue();
      await subscription.cancel();

      expect(pauses, [
        PauseState(isPaused: true, until: until),
        PauseState.running,
      ]);
    });

    test('a pause from the app is sent in milliseconds', () async {
      final until = DateTime(2026, 11, 18, 16);

      await system.setPause(PauseState(isPaused: true, until: until));

      expect(api.pause?.paused, isTrue);
      expect(api.pause?.untilMs, until.millisecondsSinceEpoch);
    });

    test('stops today count from local midnight', () async {
      final now = DateTime(2026, 11, 18, 9);
      api.stops = [
        DateTime(2026, 11, 17, 23, 59).millisecondsSinceEpoch,
        DateTime(2026, 11, 18, 0, 1).millisecondsSinceEpoch,
        DateTime(2026, 11, 18, 8).millisecondsSinceEpoch,
      ];

      expect(await system.serviceStopsToday(now: now), 2);
    });

    test('the maker comes from the manufacturer', () async {
      api.maker = 'Redmi';

      expect(await system.deviceMaker(), DeviceMaker.xiaomi);
    });
  });

  group('elsewhere', () {
    test('Android calls do nothing and answer safe defaults', () async {
      final api = _FakeApi();
      final system = FerretSystem.forTesting(api: api, platform: .none);

      await system.startService();
      await system.updateStatus(['Laptop']);
      await system.acquireMulticastLock();

      expect(api.calls, isEmpty);
      expect(await system.isIgnoringBatteryOptimizations(), isTrue);
      expect(await system.requestAddTile(), AddTileResult.unsupported);
      expect(await system.pauseState(), PauseState.running);
      expect(await system.serviceStopsToday(), 0);
    });

    test('desktops watch the network by polling', () async {
      final watcher = PollingNetworkWatcher(
        interval: const Duration(hours: 1),
        addresses: () async => const [],
      );
      final system = FerretSystem.forTesting(
        api: _FakeApi(),
        platform: .desktop,
        pollingWatcher: watcher,
      );

      final subscription = system.networkChanges.listen((_) {});
      expect(watcher.isRunning, isTrue);
      await subscription.cancel();
      expect(watcher.isRunning, isFalse);
    });
  });

  group('DeviceMaker', () {
    test('knows sub-brands', () {
      expect(DeviceMaker.fromManufacturer('POCO'), DeviceMaker.xiaomi);
      expect(DeviceMaker.fromManufacturer('HONOR'), DeviceMaker.huawei);
      expect(DeviceMaker.fromManufacturer('realme'), DeviceMaker.oppo);
      expect(DeviceMaker.fromManufacturer('iQOO'), DeviceMaker.vivo);
      expect(DeviceMaker.fromManufacturer('samsung'), DeviceMaker.samsung);
      expect(DeviceMaker.fromManufacturer('OnePlus'), DeviceMaker.oneplus);
      expect(DeviceMaker.fromManufacturer('Google'), DeviceMaker.other);
      expect(DeviceMaker.other.hasExtraKiller, isFalse);
    });
  });
}

class _FakeApi extends SystemHostApi {
  final List<String> calls = [];
  final List<bool> watching = [];
  PauseMessage? pause;
  List<int> stops = const [];
  String maker = 'Google';

  @override
  Future<void> listenForActions() async => calls.add('listenForActions');

  @override
  Future<void> setNetworkWatching(bool watching) async =>
      this.watching.add(watching);

  @override
  Future<void> startService() async => calls.add('startService');

  @override
  Future<void> updateStatus(List<String> connectedDevices) async =>
      calls.add('updateStatus');

  @override
  Future<void> acquireMulticastLock() async =>
      calls.add('acquireMulticastLock');

  @override
  Future<void> setPause(PauseMessage pause) async => this.pause = pause;

  @override
  Future<List<int>> recentServiceStops() async => stops;

  @override
  Future<String> manufacturer() async => maker;
}
