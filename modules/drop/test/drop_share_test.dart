import 'dart:async';
import 'dart:io';

import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/files.dart';
import 'support/linked_devices.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifier implements LocalNotifier {
  final List<LocalNotice> shown = [];

  /// The "couldn't send" notices, apart from those about a transfer.
  Iterable<LocalNotice> get problems =>
      shown.where((notice) => notice.id.endsWith('problem'));

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

/// The platform's share sheet: shares go in, the published devices come out.
class _FakePlugin extends FerretDrop {
  final StreamController<SharedItems> incoming = .broadcast();
  final List<List<ShareTarget>> published = [];

  @override
  Stream<SharedItems> get shares => incoming.stream;

  @override
  Future<void> setShareTargets(List<ShareTarget> targets) async =>
      published.add(targets);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late LinkedDevices link;
  late _FakePlugin plugin;
  late _FakeNotifier notifier;
  late FeatureContext context;
  late File source;
  DropFeatureUi? ui;

  List<String> sentTo() => [
    for (final transfer in link.laptop.feature.transfers) transfer.deviceId,
  ];

  Future<DropFeatureUi> start({
    List<String> filesToSend = const [],
    SendHandoff? handoff,
    Duration connectGrace = Duration.zero,
  }) async {
    final started = DropFeatureUi(
      plugin: plugin,
      feature: link.laptop.feature,
      filesToSend: filesToSend,
      handoff: handoff,
      connectGrace: connectGrace,
    );
    ui = started;
    await started.onAppStarted(context);
    return started;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => root.path,
        );
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: folderStore(Directory(p.join(root.path, 'phone'))),
    );
    plugin = _FakePlugin();
    notifier = _FakeNotifier();
    context = FeatureContext(
      engine: _FakeEngine(),
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
    );
    source = await randomFile(root, 'photo.jpg', 2048);
  });

  tearDown(() async {
    await until(
      () => link.laptop.feature.transfers.every(
        (transfer) => !transfer.status.isActive,
      ),
    );
    await ui?.dispose();
    ui = null;
    await root.delete(recursive: true);
  });

  group('send arguments', () {
    test('send with files gives their absolute paths', () {
      final paths = SendArguments.paths(
        ['send', '/tmp/a.txt', 'notes/b.txt', 'file:///tmp/c%20d.txt'],
        workingDirectory: '/home/ana',
        context: p.posix,
      );

      expect(paths, ['/tmp/a.txt', '/home/ana/notes/b.txt', '/tmp/c d.txt']);
    });

    test('anything else is not a send command', () {
      expect(SendArguments.paths(const []), isEmpty);
      expect(SendArguments.paths(const ['--verbose', 'send']), isEmpty);
      expect(SendArguments.paths(const ['send']), isEmpty);
    });
  });

  group('handoff', () {
    test('a later run hands its files to the running one', () async {
      final running = SendHandoff(root.path);
      final later = SendHandoff(root.path);
      final received = <List<String>>[];
      running.requests.listen(received.add);
      await running.listen();

      final taken = await later.handOver(['/tmp/a.txt', '/tmp/b.txt']);

      expect(taken, isTrue);
      expect(received, [
        ['/tmp/a.txt', '/tmp/b.txt'],
      ]);
      await running.dispose();
      await later.dispose();
    });

    test('with no Ferret running, the files stay with this run', () async {
      final first = SendHandoff(root.path);

      expect(await first.handOver(['/tmp/a.txt']), isFalse);
      await first.dispose();
    });

    test('a second launch wakes the running Ferret instead of starting '
        'again', () async {
      final running = SendHandoff(root.path);
      final received = <List<String>>[];
      running.requests.listen(received.add);
      await running.listen();
      final later = SendHandoff(root.path);

      expect(await later.wakeUp(), isTrue);
      expect(received, [<String>[]]);
      await running.dispose();
      await later.dispose();

      expect(await SendHandoff(root.path).wakeUp(), isFalse);
    });

    test('a Ferret that quit no longer takes files', () async {
      final running = SendHandoff(root.path);
      await running.listen();
      await running.dispose();
      final later = SendHandoff(root.path);

      expect(await later.handOver(['/tmp/a.txt']), isFalse);
      await later.dispose();
    });
  });

  group('shares', () {
    test('the connected devices are published for the share sheet', () async {
      await start();

      expect(plugin.published, hasLength(1));
      expect(plugin.published.single.single.deviceId, 'phone-id');
      expect(plugin.published.single.single.name, 'Phone');
    });

    test('a device going away is published too', () async {
      await start();

      link.drop();
      await pumpEventQueue();

      expect(plugin.published.last, isEmpty);
    });

    test('files go to the device picked in the share sheet', () async {
      await start();

      plugin.incoming.add(
        SharedItems(paths: [source.path], deviceId: 'phone-id'),
      );
      await until(() => sentTo().isNotEmpty);

      expect(sentTo(), ['phone-id']);
    });

    test('copies are deleted once sent, the files themselves stay', () async {
      await start();
      final copy = await source.copy(p.join(root.path, 'copy.jpg'));

      plugin.incoming
        ..add(SharedItems(paths: [copy.path], deviceId: 'phone-id'))
        ..add(
          SharedItems(
            paths: [source.path],
            deviceId: 'phone-id',
            keepFiles: true,
          ),
        );
      await until(() => sentTo().length == 2);
      await until(() => !copy.existsSync());

      expect(source.existsSync(), isTrue);
    });

    test('"All my devices" sends to every connected device', () async {
      await start();
      final copy = await source.copy(p.join(root.path, 'copy.jpg'));

      plugin.incoming.add(SharedItems(paths: [copy.path], everyDevice: true));
      await until(() => sentTo().isNotEmpty);

      expect(sentTo(), ['phone-id']);
    });

    test('a picked device that is gone gets a notice, not a guess', () async {
      await start();

      plugin.incoming.add(
        SharedItems(paths: [source.path], deviceId: 'tablet-id'),
      );
      await until(() => notifier.problems.isNotEmpty);

      expect(sentTo(), isEmpty);
    });

    test('a share that started Ferret waits for the device', () async {
      link.drop();
      await start(connectGrace: const Duration(seconds: 5));

      plugin.incoming.add(
        SharedItems(paths: [source.path], deviceId: 'phone-id'),
      );
      await pumpEventQueue();
      expect(sentTo(), isEmpty);
      link.connect();
      await until(() => sentTo().isNotEmpty);

      expect(sentTo(), ['phone-id']);
      expect(notifier.problems, isEmpty);
    });

    test('a share that woke Ferret long after it started waits too', () async {
      link.drop();
      await start(connectGrace: const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(seconds: 3));

      plugin.incoming.add(
        SharedItems(paths: [source.path], deviceId: 'phone-id'),
      );
      await pumpEventQueue();
      expect(sentTo(), isEmpty);
      link.connect();
      await until(() => sentTo().isNotEmpty);

      expect(sentTo(), ['phone-id']);
      expect(notifier.problems, isEmpty);
    });

    test('files Ferret was started with go to the one device', () async {
      await start(filesToSend: [source.path]);
      await until(() => sentTo().isNotEmpty);

      expect(sentTo(), ['phone-id']);
      expect(source.existsSync(), isTrue);
    });

    test(
      'a later launch with no files shows the window, sends nothing',
      () async {
        var revealed = 0;
        context = FeatureContext(
          engine: _FakeEngine(),
          navigatorKey: GlobalKey<NavigatorState>(),
          notifier: notifier,
          onReveal: () async => revealed++,
        );
        final handoff = SendHandoff(root.path);
        await start(handoff: handoff);

        await SendHandoff(root.path).wakeUp();
        await until(() => revealed > 0);

        expect(sentTo(), isEmpty);
      },
    );

    test('files a later run hands over are sent and kept', () async {
      final handoff = SendHandoff(root.path);
      await start(handoff: handoff);

      await SendHandoff(root.path).handOver([source.path]);
      await until(() => sentTo().isNotEmpty);
      await until(
        () => link.laptop.feature.transfers.every(
          (transfer) => !transfer.status.isActive,
        ),
      );

      expect(sentTo(), ['phone-id']);
      expect(source.existsSync(), isTrue);
    });
  });
}
