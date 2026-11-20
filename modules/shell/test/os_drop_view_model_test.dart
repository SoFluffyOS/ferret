import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

const _pixel = DeviceDropTarget(
  deviceId: 'pixel-id',
  name: 'Pixel 7',
  isConnected: true,
);
const _tablet = DeviceDropTarget(
  deviceId: 'tablet-id',
  name: 'Tablet',
  isConnected: false,
);

/// The Pixel at y 100-200, the offline tablet at 200-300, "All my
/// devices" at 300-360, nothing above.
class _FakeFinder implements DropTargetFinder {
  @override
  FilesDropTarget? find(Offset position) => switch (position.dy) {
    >= 100 && < 200 => _pixel,
    >= 200 && < 300 => _tablet,
    >= 300 && < 360 => const AllDevicesDropTarget(),
    _ => null,
  };
}

const _overPixel = Offset(50, 150);
const _overTablet = Offset(50, 250);
const _overAll = Offset(50, 330);
const _overNothing = Offset(50, 20);

/// Stands in for the 600 ms and 1.5 s holds, so tests stay quick.
const _grace = Duration(milliseconds: 40);

/// Stands in for the 3 s undo window.
const _undo = Duration(milliseconds: 40);

class _Keeper implements DropReceiver {
  final List<List<String>> files = [];
  final List<(String, bool)> texts = [];

  @override
  void hover({required bool over}) {}

  @override
  Future<bool> takeFiles(List<String> paths) async {
    files.add(paths);
    return true;
  }

  @override
  Future<bool> takeText(String text, {required bool isLink}) async {
    texts.add((text, isLink));
    return true;
  }
}

Future<void> _wait(int milliseconds) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

void main() {
  late List<DeviceDropTarget> devices;
  late List<(List<String>, String?)> sent;
  late MemorySettingsStore settings;
  late List<(String, String?, bool)> sentText;
  late StreamController<FilesSendProgress> progress;
  late List<bool> allowed;
  late int finished;
  late int failed;
  late int notifications;
  late OsDropViewModel viewModel;

  setUp(() {
    devices = [_pixel, _tablet];
    sent = [];
    settings = MemorySettingsStore();
    sentText = [];
    progress = StreamController<FilesSendProgress>();
    allowed = [];
    finished = 0;
    failed = 0;
    notifications = 0;
    viewModel = OsDropViewModel(
      devices: () => devices,
      send: (paths, deviceId) async {
        sent.add((paths, deviceId));
        return progress.stream;
      },
      sendText: (text, deviceId, {required isLink}) async {
        sentText.add((text, deviceId, isLink));
        return progress.stream;
      },
      settings: settings,
      finder: _FakeFinder(),
      onAllowedChanged: allowed.add,
      onFinished: () => finished++,
      onFailed: () => failed++,
      leaveGrace: _grace,
      sentHold: _grace,
      undoWindow: _undo,
    )..addListener(() => notifications++);
  });

  tearDown(() => viewModel.dispose());

  test('dragging highlights the target under the pointer', () {
    viewModel.enter(_overPixel, fileCount: 3);

    expect(viewModel.phase, isA<DropChoosing>());
    expect(viewModel.fileCount, 3);
    expect(viewModel.hovered, _pixel);
    expect(allowed.last, isTrue);

    viewModel.move(_overTablet);
    expect(viewModel.hovered, _tablet);
    expect(allowed.last, isFalse);
  });

  test('moving only notifies when the target changes', () {
    viewModel.enter(_overNothing);
    expect(notifications, 1);

    viewModel
      ..move(const Offset(60, 30))
      ..move(const Offset(70, 40));
    expect(notifications, 1);

    viewModel
      ..move(_overPixel)
      ..move(const Offset(80, 160));
    expect(notifications, 2);
  });

  test('a drop on a device sends only there', () async {
    viewModel.enter(_overPixel, fileCount: 1);
    await viewModel.drop(['/a.jpg'], _overPixel);

    expect(sent.single.$1, ['/a.jpg']);
    expect(sent.single.$2, 'pixel-id');
    expect(viewModel.phase, isA<DropSending>());
    expect(viewModel.sendTarget, _pixel);
  });

  test('a dropped folder counts as a folder, not a file', () async {
    final temp = Directory.systemTemp.createTempSync('ferret_drop_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final folder = Directory('${temp.path}/Photos')..createSync();
    final file = File('${temp.path}/notes.txt')..writeAsStringSync('hi');

    viewModel.enter(_overPixel, fileCount: 2);
    await viewModel.drop([folder.path, file.path], _overPixel);

    expect(viewModel.fileCount, 2);
    expect(viewModel.folderCount, 1);
  });

  test('a drop on "All my devices" sends to every device', () async {
    viewModel.enter(_overAll);
    await viewModel.drop(['/a.jpg'], _overAll);

    expect(sent.single.$2, isNull);
  });

  test('offline devices and gaps refuse the drop', () async {
    viewModel.enter(_overTablet);
    await viewModel.drop(['/a.jpg'], _overTablet);
    viewModel.enter(_overNothing);
    await viewModel.drop(['/a.jpg'], _overNothing);

    expect(sent, isEmpty);
    expect(viewModel.phase, isA<DropIdle>());
  });

  test('progress, then "Sent" for a moment, then back to rest', () async {
    viewModel.enter(_overPixel);
    await viewModel.drop(['/a.jpg'], _overPixel);

    progress.add(const FilesSending(0.5));
    await pumpEventQueue();
    expect(viewModel.phase, isA<DropSending>());
    expect((viewModel.phase as DropSending).fraction, 0.5);

    progress.add(const FilesSent());
    await pumpEventQueue();
    expect(viewModel.phase, isA<DropSent>());

    await _wait(60);
    expect(viewModel.phase, isA<DropIdle>());
    expect(finished, 1);
  });

  test('a failure stays until people try again', () async {
    viewModel.enter(_overPixel);
    await viewModel.drop(['/a.jpg'], _overPixel);
    progress.add(const FilesSendFailed('It went offline.'));
    await pumpEventQueue();

    expect(viewModel.phase, isA<DropFailed>());
    expect((viewModel.phase as DropFailed).reason, 'It went offline.');
    expect(failed, 1);

    progress = StreamController<FilesSendProgress>();
    await viewModel.retry();
    expect(sent, hasLength(2));
    expect(sent.last.$2, 'pixel-id');
  });

  test('leaving keeps the targets briefly, coming back keeps them', () async {
    viewModel
      ..enter(_overPixel)
      ..exit();
    await _wait(10);
    expect(viewModel.phase, isA<DropChoosing>());

    viewModel.enter(_overPixel);
    await _wait(60);
    expect(viewModel.phase, isA<DropChoosing>());

    viewModel.exit();
    await _wait(60);
    expect(viewModel.phase, isA<DropIdle>());
    expect(sent, isEmpty);
  });

  test('a blind drop on the icon goes to the only connected device', () async {
    final outcome = await viewModel.dropOnIcon(['/a.jpg']);

    expect(outcome, isA<IconDropPending>());
    expect((outcome as IconDropPending).target, _pixel);
    expect(viewModel.pendingTarget, _pixel);
    expect(sent, isEmpty, reason: 'it waits for the undo window');

    await _wait(80);
    expect(sent.single.$2, 'pixel-id');
    expect(viewModel.pendingTarget, isNull);
  });

  test('undo within the window keeps a blind drop from going', () async {
    await viewModel.dropOnIcon(['/a.jpg']);
    await _wait(10);

    expect(viewModel.undoIconDrop(), isTrue);
    await _wait(80);

    expect(sent, isEmpty);
    expect(viewModel.pendingTarget, isNull);
    expect(viewModel.undoIconDrop(), isFalse);
  });

  test('undo after the window has nothing left to stop', () async {
    await viewModel.dropOnIcon(['/a.jpg']);
    await _wait(80);

    expect(viewModel.undoIconDrop(), isFalse);
    expect(sent.single.$1, ['/a.jpg']);
  });

  test('a second blind drop replaces the one still waiting', () async {
    await viewModel.dropOnIcon(['/a.jpg']);
    await viewModel.dropOnIcon(['/b.jpg']);
    await _wait(80);

    expect(sent.single.$1, ['/b.jpg']);
  });

  test('Put it on the shelf keeps icon drops on this computer', () async {
    final keeper = _Keeper();

    final outcome = await viewModel.dropOnIcon(
      ['/a.jpg'],
      mode: .shelf,
      keeper: keeper,
    );
    await _wait(80);

    expect(outcome, isA<IconDropKept>());
    expect(keeper.files.single, ['/a.jpg']);
    expect(sent, isEmpty);
  });

  test('Ask every time holds icon drops for a device to be picked', () async {
    final outcome = await viewModel.dropOnIcon(['/a.jpg'], mode: .ask);
    await _wait(80);

    expect(outcome, isA<IconDropHeld>());
    expect((viewModel.phase as DropChoosing).held, isTrue);
    expect(sent, isEmpty);
  });

  test('text and links dropped on the icon go to the shelf', () async {
    final keeper = _Keeper();

    expect(
      await viewModel.dropTextOnIcon(
        'Meet at 6',
        isLink: false,
        keeper: keeper,
      ),
      isA<IconDropKept>(),
    );
    expect(
      await viewModel.dropTextOnIcon(
        'https://example.com',
        isLink: false,
        keeper: keeper,
      ),
      isA<IconDropKept>(),
    );
    expect(keeper.texts, [('Meet at 6', false), ('https://example.com', true)]);
    expect(sentText, isEmpty);
    expect(
      await viewModel.dropTextOnIcon('Hi', isLink: false),
      isA<IconDropRefused>(),
    );
  });

  test('the blind target names the device a quick drop goes to', () {
    expect(viewModel.blindTarget, _pixel);

    devices = [
      _pixel,
      const DeviceDropTarget(deviceId: 'ipad', name: 'iPad', isConnected: true),
    ];
    expect(viewModel.blindTarget, isNull);

    devices = [_tablet];
    expect(viewModel.blindTarget, isNull);
  });

  test('with two devices connected a blind drop asks which', () async {
    devices = [
      _pixel,
      const DeviceDropTarget(deviceId: 'ipad', name: 'iPad', isConnected: true),
    ];

    await viewModel.dropOnIcon(['/a.jpg', '/b.jpg']);
    expect(sent, isEmpty);
    expect(viewModel.phase, isA<DropChoosing>());
    expect((viewModel.phase as DropChoosing).held, isTrue);
    expect(viewModel.fileCount, 2);

    await viewModel.pick(_tablet);
    expect(sent, isEmpty);

    await viewModel.pick(const AllDevicesDropTarget());
    expect(sent.single.$1, ['/a.jpg', '/b.jpg']);
    expect(sent.single.$2, isNull);
  });

  test('a blind drop goes to the device files were last dropped on', () async {
    const ipad = DeviceDropTarget(
      deviceId: 'ipad',
      name: 'iPad',
      isConnected: true,
    );
    devices = [_pixel, ipad];
    viewModel.enter(_overPixel, fileCount: 1);
    await viewModel.drop(['/first.jpg'], _overPixel);
    progress.add(const FilesSent());
    await _wait(60);
    progress = StreamController<FilesSendProgress>();

    final outcome = await viewModel.dropOnIcon(['/blind.jpg']);
    await _wait(80);

    expect(outcome, isA<IconDropPending>());
    expect(sent.last.$1, ['/blind.jpg']);
    expect(sent.last.$2, 'pixel-id');
    expect(viewModel.phase, isA<DropSending>());
  });

  test('a blind drop asks when the last device is offline', () async {
    settings = MemorySettingsStore({
      OsDropViewModel.lastDeviceKey: 'tablet-id',
    });
    devices = [
      _pixel,
      const DeviceDropTarget(deviceId: 'ipad', name: 'iPad', isConnected: true),
    ];
    final asking = OsDropViewModel(
      devices: () => devices,
      send: (paths, deviceId) async => progress.stream,
      settings: settings,
      finder: _FakeFinder(),
    );
    addTearDown(asking.dispose);

    expect(await asking.dropOnIcon(['/a.jpg']), isA<IconDropHeld>());
    expect(asking.phase, isA<DropChoosing>());
  });

  group('text and links', () {
    test('text dropped on a device goes to its clipboard', () async {
      viewModel.enter(_overPixel, fileCount: 1, kind: .text);
      expect(viewModel.kind, DropKind.text);

      await viewModel.dropText('Meet at 6', _overPixel, isLink: false);

      expect(sentText.single, ('Meet at 6', 'pixel-id', false));
      expect(sent, isEmpty);
      expect(viewModel.phase, isA<DropSending>());
    });

    test('a link, or a lone web address, opens on the device', () async {
      await viewModel.dropText(
        'https://example.com/a',
        _overAll,
        isLink: true,
      );
      progress = StreamController<FilesSendProgress>();
      await viewModel.dropText(
        ' https://ferret.example/page ',
        _overPixel,
        isLink: false,
      );

      expect(sentText, [
        ('https://example.com/a', null, true),
        (' https://ferret.example/page ', 'pixel-id', true),
      ]);
      expect(viewModel.kind, DropKind.link);
    });

    test('words around a link stay text', () {
      expect(
        DropKind.ofText('see https://example.com', isLink: false),
        DropKind.text,
      );
      expect(DropKind.ofText('example.com', isLink: false), DropKind.text);
    });

    test('text on an offline device or a gap is refused', () async {
      await viewModel.dropText('hi', _overTablet, isLink: false);
      await viewModel.dropText('hi', _overNothing, isLink: false);

      expect(sentText, isEmpty);
      expect(viewModel.phase, isA<DropIdle>());
    });

    test('trying again sends the same text again', () async {
      await viewModel.dropText('hi', _overPixel, isLink: false);
      progress.add(const FilesSendFailed('offline'));
      await _wait(0);
      progress = StreamController<FilesSendProgress>();

      await viewModel.retry();

      expect(sentText, [('hi', 'pixel-id', false), ('hi', 'pixel-id', false)]);
    });
  });
}
