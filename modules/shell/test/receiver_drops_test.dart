import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

const _pixel = DeviceDropTarget(
  deviceId: 'pixel-id',
  name: 'Pixel 7',
  isConnected: true,
);

class _Shelf implements DropReceiver {
  final List<bool> hovers = [];
  final List<List<String>> files = [];
  final List<(String, bool)> texts = [];

  @override
  void hover({required bool over}) => hovers.add(over);

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

/// A pane at y 0-100, the Pixel's row at 100-200, the shelf at 400-440.
class _Finder implements DropTargetFinder {
  _Finder(this.shelf);

  final _Shelf shelf;

  @override
  FilesDropTarget? find(Offset position) => switch (position.dy) {
    < 100 => const PaneDropTarget(_pixel),
    >= 100 && < 200 => _pixel,
    >= 400 && < 440 => ReceiverDropTarget(shelf),
    _ => null,
  };
}

const _overPane = Offset(50, 50);
const _overPixel = Offset(50, 150);
const _overShelf = Offset(50, 420);

void main() {
  late _Shelf shelf;
  late List<(List<String>, String?)> sent;
  late List<bool> allowed;
  late OsDropViewModel viewModel;

  setUp(() {
    shelf = _Shelf();
    sent = [];
    allowed = [];
    viewModel = OsDropViewModel(
      devices: () => [_pixel],
      send: (paths, deviceId) async {
        sent.add((paths, deviceId));
        return const Stream.empty();
      },
      sendText: (text, deviceId, {required isLink}) async => null,
      finder: _Finder(shelf),
      onAllowedChanged: allowed.add,
    );
  });

  tearDown(() => viewModel.dispose());

  test('files dropped on the shelf are kept, not sent', () async {
    viewModel.enter(_overShelf, fileCount: 1);
    expect(shelf.hovers, [true]);

    await viewModel.drop(['/tmp/a.pdf'], _overShelf);

    expect(shelf.files, [
      ['/tmp/a.pdf'],
    ]);
    expect(sent, isEmpty);
    expect(viewModel.phase, isA<DropIdle>());
    expect(shelf.hovers, [true, false]);
  });

  test('text dropped on the shelf keeps whether it is a link', () async {
    viewModel.enter(_overShelf, kind: .text);

    await viewModel.dropText('https://example.com', _overShelf, isLink: false);

    expect(shelf.texts, [('https://example.com', true)]);
  });

  test('the shelf learns when the drag moves off it', () {
    viewModel
      ..enter(_overShelf)
      ..move(_overPixel);

    expect(shelf.hovers, [true, false]);
    expect(viewModel.hovered, _pixel);
  });

  test('a drag from Ferret itself lands on rows and the shelf only', () async {
    viewModel.enter(_overPane, fromApp: true);

    expect(viewModel.fromApp, isTrue);
    expect(viewModel.hovered, isNull);
    expect(allowed.last, isFalse);

    viewModel.move(_overPixel);
    expect(allowed.last, isTrue);

    await viewModel.drop(['/tmp/shelf/a.pdf'], _overPixel);
    expect(sent.single.$2, 'pixel-id');
  });

  test('a drag from Ferret let go over a pane sends nothing', () async {
    viewModel.enter(_overPane, fromApp: true);

    await viewModel.drop(['/tmp/photo.jpg'], _overPane);

    expect(sent, isEmpty);
    expect(viewModel.fromApp, isFalse);
  });
}
