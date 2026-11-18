import 'dart:async';

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

Future<void> _wait(int milliseconds) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

void main() {
  late List<DeviceDropTarget> devices;
  late List<(List<String>, String?)> sent;
  late StreamController<FilesSendProgress> progress;
  late List<bool> allowed;
  late int finished;
  late int failed;
  late int notifications;
  late OsDropViewModel viewModel;

  setUp(() {
    devices = [_pixel, _tablet];
    sent = [];
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
      finder: _FakeFinder(),
      onAllowedChanged: allowed.add,
      onFinished: () => finished++,
      onFailed: () => failed++,
      leaveGrace: _grace,
      sentHold: _grace,
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
    await viewModel.dropBlind(['/a.jpg']);

    expect(sent.single.$2, 'pixel-id');
  });

  test('with two devices connected a blind drop asks which', () async {
    devices = [
      _pixel,
      const DeviceDropTarget(deviceId: 'ipad', name: 'iPad', isConnected: true),
    ];

    await viewModel.dropBlind(['/a.jpg', '/b.jpg']);
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
}
