import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

PlatformPowerState stateOf({
  bool installed = false,
  bool running = false,
  bool granted = false,
  bool rootFound = false,
  bool rootGranted = false,
  PlatformRootManager manager = .none,
}) => PlatformPowerState(
  shizukuInstalled: installed,
  shizukuRunning: running,
  shizukuGranted: granted,
  rootFound: rootFound,
  rootGranted: rootGranted,
  rootManager: manager,
  notificationAccess: false,
  messagesAndCalls: true,
  batteryUnrestricted: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Shizuku flags become the next thing to fix', () {
    ShizukuStatus shizukuOf(PlatformPowerState state) =>
        PigeonPowerPlatform.statusOf(state).shizuku;

    expect(shizukuOf(stateOf()), ShizukuStatus.notInstalled);
    expect(shizukuOf(stateOf(installed: true)), ShizukuStatus.notRunning);
    expect(
      shizukuOf(stateOf(installed: true, running: true)),
      ShizukuStatus.notAuthorized,
    );
    expect(
      shizukuOf(stateOf(installed: true, running: true, granted: true)),
      ShizukuStatus.ready,
    );
    expect(
      shizukuOf(stateOf(installed: true, granted: true)),
      ShizukuStatus.notRunning,
    );
  });

  test('root flags and the manager are carried over', () {
    final found = PigeonPowerPlatform.statusOf(
      stateOf(rootFound: true, manager: .kernelSu),
    );
    final granted = PigeonPowerPlatform.statusOf(
      stateOf(rootFound: true, rootGranted: true, manager: .magisk),
    );

    expect(found.root, RootStatus.found);
    expect(found.rootManager, RootManager.kernelSu);
    expect(found.messagesAndCalls, isTrue);
    expect(granted.root, RootStatus.granted);
    expect(PigeonPowerPlatform.statusOf(stateOf()).root, RootStatus.notFound);
  });

  test(
    'calls go to the matching backend and the standard tier to none',
    () async {
      final api = _FakeHostApi()
        ..clip = PlatformPowerClip(text: 'hello', sensitive: true);
      final platform = PigeonPowerPlatform(api: api);

      final clip = await platform.readClipboard(.root);
      final none = await platform.readClipboard(.standard);
      await platform.startClipboardWatch(.shizuku);
      await platform.startClipboardWatch(.standard);
      final granted = await platform.grant(.shizuku, .batteryUnrestricted);
      final refused = await platform.grant(.standard, .batteryUnrestricted);

      expect(clip?.text, 'hello');
      expect(clip?.sensitive, isTrue);
      expect(none, isNull);
      expect(granted, isTrue);
      expect(refused, isFalse);
      expect(api.calls, [
        'read:root',
        'watch:shizuku',
        'grant:shizuku:batteryUnrestricted',
      ]);
    },
  );

  test('native events reach the streams, empty clips do not', () async {
    final platform = PigeonPowerPlatform(api: _FakeHostApi());
    final clips = <PowerClip>[];
    final statuses = <PowerStatus>[];
    var stops = 0;
    platform.clipboardChanges.listen(clips.add);
    platform.statusChanges.listen(statuses.add);
    platform.watchStops.listen((_) => stops++);

    platform.onClipboardChanged(PlatformPowerClip(text: '', sensitive: false));
    platform.onClipboardChanged(PlatformPowerClip(text: 'x', sensitive: true));
    platform.onStateChanged(stateOf(installed: true, running: true));
    platform.onClipboardWatchStopped();
    await Future<void>.delayed(Duration.zero);

    expect(clips.single.sensitive, isTrue);
    expect(statuses.single.shizuku, ShizukuStatus.notAuthorized);
    expect(stops, 1);
  });
}

class _FakeHostApi extends PowerHostApi {
  PlatformPowerClip? clip;
  final List<String> calls = [];

  @override
  Future<PlatformPowerClip?> readClipboard(PlatformPowerBackend backend) async {
    calls.add('read:${backend.name}');
    return clip;
  }

  @override
  Future<void> startClipboardWatch(PlatformPowerBackend backend) async =>
      calls.add('watch:${backend.name}');

  @override
  Future<bool> grant(
    PlatformPowerBackend backend,
    PlatformPowerGrant grant,
  ) async {
    calls.add('grant:${backend.name}:${grant.name}');
    return true;
  }
}
