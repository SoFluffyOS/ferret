import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApi implements MenubarHostApi {
  final List<(MenubarIconState, double, String)> icons = [];

  @override
  Future<void> setIconState(
    MenubarIconState state,
    double progress,
    String tooltip,
  ) async => icons.add((state, progress, tooltip));

  final List<(String, String, double, double, double)> pictureWindows = [];
  int drags = 0;
  final List<(double, double)> pictureSizes = [];

  @override
  Future<bool> isWindowSupported() async => true;

  @override
  Future<int> openPictureWindow(
    String id,
    String title,
    double width,
    double height,
    double barHeight,
    bool fullScreen,
  ) async {
    pictureWindows.add((id, title, width, height, barHeight));
    return 3;
  }

  @override
  Future<void> setPictureWindowSize(double width, double height) async =>
      pictureSizes.add((width, height));

  @override
  Future<void> dragPictureWindow() async => drags++;

  final List<List<MenubarPromisedFile>> promisedDrags = [];
  final List<(String, bool)> textDrags = [];
  bool dragStarts = true;

  @override
  Future<bool> startPromisedFileDrag(
    int viewId,
    List<MenubarPromisedFile> files,
  ) async {
    promisedDrags.add(files);
    return dragStarts;
  }

  @override
  Future<bool> startTextDrag(int viewId, String text, bool isLink) async {
    textDrags.add((text, isLink));
    return dragStarts;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the icon state reaches the Mac with its progress kept within 0 to 1',
    () async {
      final api = _RecordingApi();
      final menubar = FerretMenubar(api: api);

      await menubar.setIconState(.paused, tooltip: 'Ferret · Paused');
      await menubar.setIconState(.working, progress: 0.4);
      await menubar.setIconState(.working, progress: 1.7);

      expect(api.icons, [
        (MenubarIconState.paused, 0.0, 'Ferret · Paused'),
        (MenubarIconState.working, 0.4, 'Ferret'),
        (MenubarIconState.working, 1.0, 'Ferret'),
      ]);
    },
    skip: !Platform.isMacOS,
  );

  test(
    'a picture window opens in the picture\'s shape with its bar, turns '
    'with it, moves from the bar, and says when it closed',
    () async {
      final api = _RecordingApi();
      final menubar = FerretMenubar(api: api);
      final closed = <int>[];
      final subscription = menubar.pictureWindowClosed.listen(closed.add);

      final viewId = await menubar.openPictureWindow(
        id: 'pixel',
        title: 'Pixel 9 — Screen',
        size: const Size(1080, 2400),
        barHeight: 32,
      );
      await menubar.setPictureWindowSize(const Size(2400, 1080));
      await menubar.dragPictureWindow();
      menubar.onPictureWindowClosed(3);
      await pumpEventQueue();

      expect(viewId, 3);
      expect(api.pictureWindows, [
        ('pixel', 'Pixel 9 — Screen', 1080.0, 2400.0, 32.0),
      ]);
      expect(api.pictureSizes, [(2400.0, 1080.0)]);
      expect(api.drags, 1);
      expect(closed, [3]);
      await subscription.cancel();
    },
    skip: !Platform.isMacOS,
  );

  test('drags over the popover arrive in order as Dart events', () async {
    final menubar = FerretMenubar();
    final drags = <PopoverDrag>[];
    final subscription = menubar.drags.listen(drags.add);

    menubar
      ..onDragEntered(7, 10, 20, 3, .files, false)
      ..onDragUpdated(7, 12, 24)
      ..onDragPerformed(7, ['/tmp/a.txt'], 12, 24)
      ..onDragExited(7);
    await pumpEventQueue();

    expect(drags, hasLength(4));
    expect(
      drags.first,
      isA<PopoverDragEntered>()
          .having((drag) => drag.position, 'position', const Offset(10, 20))
          .having((drag) => drag.fileCount, 'fileCount', 3),
    );
    expect(
      drags[1],
      isA<PopoverDragMoved>().having(
        (drag) => drag.position,
        'position',
        const Offset(12, 24),
      ),
    );
    expect(
      drags[2],
      isA<PopoverDragDropped>().having(
        (drag) => drag.paths,
        'paths',
        ['/tmp/a.txt'],
      ),
    );
    expect(drags.last, isA<PopoverDragExited>());
    await subscription.cancel();
  });

  test('text and links dropped on a view arrive with their kind', () async {
    final menubar = FerretMenubar();
    final drags = <PopoverDrag>[];
    final subscription = menubar.drags.listen(drags.add);

    menubar
      ..onDragEntered(7, 10, 20, 1, .link, true)
      ..onTextDropped(7, 'https://example.com', true, 12, 24);
    await pumpEventQueue();

    expect(
      drags.first,
      isA<PopoverDragEntered>()
          .having((drag) => drag.kind, 'kind', MenubarDragKind.link)
          .having((drag) => drag.fromApp, 'fromApp', true),
    );
    expect(
      drags.last,
      isA<PopoverTextDropped>()
          .having((drag) => drag.text, 'text', 'https://example.com')
          .having((drag) => drag.isLink, 'isLink', true)
          .having((drag) => drag.position, 'position', const Offset(12, 24)),
    );
    await subscription.cancel();
  });

  test(
    'a promised file is fetched only when the Mac asks for it, once',
    () async {
      final api = _RecordingApi();
      final menubar = FerretMenubar(api: api);
      var fetches = 0;

      final started = await menubar.startPromisedFileDrag(7, [
        PromisedDragFile(
          name: 'IMG_2041.jpg',
          image: Uint8List.fromList([1, 2, 3]),
          fetch: () async {
            fetches++;
            return '/tmp/IMG_2041.jpg';
          },
        ),
      ]);
      final promised = api.promisedDrags.single.single;

      expect(started, isTrue);
      expect(promised.name, 'IMG_2041.jpg');
      expect(promised.image, [1, 2, 3]);
      expect(fetches, 0);
      expect(
        await menubar.onPromisedFileWanted(promised.id),
        '/tmp/IMG_2041.jpg',
      );
      expect(await menubar.onPromisedFileWanted(promised.id), isNull);
      expect(fetches, 1);
    },
    skip: !Platform.isMacOS,
  );

  test(
    'a promised drag that never started is forgotten, and a failed fetch '
    'gives nothing',
    () async {
      final api = _RecordingApi()..dragStarts = false;
      final menubar = FerretMenubar(api: api);

      await menubar.startPromisedFileDrag(7, [
        PromisedDragFile(name: 'a.jpg', fetch: () async => '/tmp/a.jpg'),
      ]);
      expect(
        await menubar.onPromisedFileWanted(
          api.promisedDrags.single.single.id,
        ),
        isNull,
      );

      api.dragStarts = true;
      await menubar.startPromisedFileDrag(7, [
        PromisedDragFile(name: 'b.jpg', fetch: () => throw StateError('gone')),
      ]);
      expect(
        await menubar.onPromisedFileWanted(api.promisedDrags.last.single.id),
        isNull,
      );
    },
    skip: !Platform.isMacOS,
  );

  test('text drags say whether they are a link', () async {
    final api = _RecordingApi();
    final menubar = FerretMenubar(api: api);

    await menubar.startTextDrag(7, 'hello');
    await menubar.startTextDrag(7, 'https://example.com', isLink: true);
    await menubar.startTextDrag(7, '');

    expect(api.textDrags, [('hello', false), ('https://example.com', true)]);
  }, skip: !Platform.isMacOS);
}
