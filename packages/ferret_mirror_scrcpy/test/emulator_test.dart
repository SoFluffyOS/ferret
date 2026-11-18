@Tags(['emulator'])
library;

import 'dart:async';
import 'dart:io';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Runs against a real Android emulator, with the real adb and the real
/// scrcpy server (downloaded once into the system's temp folder):
///
///     fvm flutter test --run-skipped --tags emulator
void main() {
  late ScrcpyRoute route;
  late AdbClient adb;
  late MirrorTarget emulator;

  setUpAll(() async {
    final executable = AdbLocator().find();
    if (executable == null) {
      fail('adb not found on this computer');
    }

    adb = AdbClient(executable);
    route = ScrcpyRoute(
      supportDirectory: () async => Directory(
        p.join(Directory.systemTemp.path, 'ferret_mirror_scrcpy_test'),
      ),
    );

    final targets = await route.targets.first;
    emulator = targets.firstWhere(
      (target) => target.id.startsWith('emulator-'),
      orElse: () => fail('No running emulator in: ${targets.map((t) => t.id)}'),
    );
  });

  tearDownAll(() => route.dispose());

  test('is ready, and lists the emulator as a cabled target', () async {
    expect(await route.status(), isA<RouteReady>());
    expect(emulator.routeId, 'adb');
    expect(emulator.wireless, isFalse);
    expect(emulator.name, isNotEmpty);
  });

  test('downloads Google\'s adb, checks it and runs it', () async {
    final directory = await Directory.systemTemp.createTemp('adb_installer');
    addTearDown(() => directory.delete(recursive: true));
    final installer = AdbInstaller(directory: () async => directory);

    final executable = await installer.install();
    final version = await Process.run(executable, ['version']);

    expect(executable, startsWith(await installer.installDirectory()));
    expect('${version.stdout}', contains(PlatformToolsRelease.version));
    expect(await installer.install(), executable);
  });

  test(
    'shows the screen, follows a rotation, controls, and cleans up',
    () async {
      await adb.shell(emulator.id, ['input', 'keyevent', 'KEYCODE_WAKEUP']);
      await _lockRotation(adb, emulator.id);
      await adb.shell(emulator.id, [
        'am',
        'start',
        '-a',
        'android.settings.SETTINGS',
      ]);

      final feed = await route.open(
        emulator,
        const FeedOptions(
          codecs: [.h264],
          maxSize: 1280,
          maxFps: 30,
          bitrate: 2000000,
          control: true,
        ),
      );
      final events = _Recorder(feed.events);
      final control = feed.control;
      if (control == null) {
        fail('Control was asked for');
      }

      final firstConfig = await events.next<FeedConfigured>();
      final config = firstConfig.config;
      expect(config.codec, MirrorCodec.h264);
      expect(config.width, greaterThan(0));
      expect(config.height, greaterThan(0));
      expect(config.width > config.height ? config.width : config.height, 1280);
      expect(H264Sps.parse(config.sps ?? fail('No SPS')).width, config.width);
      expect(
        (config.pps ?? fail('No PPS'))[0] & 0x1f,
        AnnexB.pictureParameterSet,
      );

      final firstFrame = await events.next<FeedFrame>();
      expect(firstFrame.frame.keyframe, isTrue);
      expect(_unitTypes(firstFrame.frame), containsAll([7, 8, 5]));

      // Something has to move for the encoder to make pictures.
      control.press(.notifications);
      final moving = await events.nextWhere<FeedFrame>(
        (event) => !event.frame.keyframe,
      );
      expect(moving.frame.ptsUs, greaterThan(firstFrame.frame.ptsUs));
      expect(_unitTypes(moving.frame), contains(1));
      await adb.shell(emulator.id, ['cmd', 'statusbar', 'collapse']);

      events.skipToNow();
      await feed.requestKeyframe();
      final asked = await events.nextWhere<FeedFrame>(
        (event) => event.frame.keyframe,
      );
      expect(_unitTypes(asked.frame), contains(5));

      control.press(.rotate);
      final rotated = await events.next<FeedConfigured>();
      expect(rotated.config.width, config.height);
      expect(rotated.config.height, config.width);
      final afterRotation = await events.next<FeedFrame>();
      expect(afterRotation.frame.keyframe, isTrue);

      control.press(.rotate);
      final back = await events.next<FeedConfigured>();
      expect(back.config.width, config.width);

      final marker = 'ferret${DateTime.now().millisecondsSinceEpoch}';
      control.text(marker);
      control.pointer(const MirrorPointer(phase: .down, x: 0.5, y: 0.5));
      control.pointer(const MirrorPointer(phase: .up, x: 0.5, y: 0.5));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final recentInput = await adb.shell(emulator.id, ['dumpsys', 'input']);
      control.press(.home);

      await Future<void>.delayed(const Duration(milliseconds: 500));
      final frameCount = events.count<FeedFrame>();
      await feed.stop();
      final ended = await events.next<FeedEnded>();
      expect(ended.reason, FeedEnd.stoppedHere);
      expect(frameCount, greaterThanOrEqualTo(3));

      final forwards = await Process.run(adb.executable, [
        '-s',
        emulator.id,
        'forward',
        '--list',
      ]);
      expect('${forwards.stdout}', isNot(contains('scrcpy_')));
      final leftovers = await adb.shell(emulator.id, ['ls', '/data/local/tmp']);
      expect(leftovers, isNot(contains('ferret-scrcpy-server')));
      final processes = await adb.shell(emulator.id, [
        'ps',
        '-A',
        '-o',
        'ARGS',
      ]);
      expect(processes, isNot(contains('com.genymobile.scrcpy.Server')));

      final size = RegExp(
        r'(\d+)x(\d+)',
      ).firstMatch(await adb.shell(emulator.id, ['wm', 'size']));
      final centerX = int.parse(size?.group(1) ?? '0') / 2;
      final centerY = int.parse(size?.group(2) ?? '0') / 2;
      expect(recentInput, contains('pointers=[0: ($centerX, $centerY)]'));
      expect(recentInput, contains('source=TOUCHSCREEN'));
      expect(recentInput, contains('source=KEYBOARD'));

      // ignore: avoid_print
      print(
        'Emulator feed: ${config.width}x${config.height}, '
        '$frameCount frames, rotated to '
        '${rotated.config.width}x${rotated.config.height}',
      );
    },
  );
}

/// Upright and not following the sensor, so "rotate" has one meaning.
Future<void> _lockRotation(AdbClient adb, String serial) async {
  const settings = ['settings', 'put', 'system'];
  await adb.shell(serial, [...settings, 'accelerometer_rotation', '0']);
  await adb.shell(serial, [...settings, 'user_rotation', '0']);
}

List<int> _unitTypes(MirrorFrame frame) =>
    AnnexB.units(frame.data).map(AnnexB.typeOf).toList();

/// Keeps every event of a feed, and hands them out in order by kind.
class _Recorder {
  _Recorder(Stream<FeedEvent> events) {
    events.listen((event) {
      _seen.add(event);
      _arrived.add(null);
    });
  }

  static const Duration _patience = Duration(seconds: 20);

  final List<FeedEvent> _seen = [];
  final StreamController<void> _arrived = .broadcast();
  int _cursor = 0;

  int count<T extends FeedEvent>() => _seen.whereType<T>().length;

  void skipToNow() => _cursor = _seen.length;

  Future<T> next<T extends FeedEvent>() => nextWhere<T>((_) => true);

  Future<T> nextWhere<T extends FeedEvent>(bool Function(T event) test) async {
    final deadline = DateTime.now().add(_patience);
    while (true) {
      while (_cursor < _seen.length) {
        final event = _seen[_cursor++];
        if (event is T && test(event)) {
          return event;
        }

        if (event is FeedEnded) {
          fail('Feed ended early: ${event.reason} ${event.detail}');
        }
      }

      final left = deadline.difference(DateTime.now());
      if (left.isNegative) {
        fail('No $T within $_patience');
      }

      await _arrived.stream.first.timeout(left, onTimeout: () {});
    }
  }
}
