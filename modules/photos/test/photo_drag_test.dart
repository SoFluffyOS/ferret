import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/photos.dart';
import 'package:protocol/photos.dart';

class _RecordingDragOut implements DragOut {
  final List<List<String>> fileDrags = [];
  final List<List<PromisedFile>> promisedDrags = [];

  @override
  Future<bool> files(int viewId, List<String> paths) async {
    fileDrags.add(paths);
    return true;
  }

  @override
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files) async {
    promisedDrags.add(files);
    return true;
  }

  @override
  Future<bool> text(int viewId, String text, {bool isLink = false}) async =>
      false;
}

/// A gallery whose photos are never fetched for real: the test says what
/// is here already and records what is asked for.
class _Gallery extends PhotoGalleryViewModel {
  _Gallery() : super(PhotosFeature(), 'pixel');

  final Map<String, String> copies = {};
  final List<String> fetched = [];

  @override
  String? localCopy(String photoId) => copies[photoId];

  @override
  Future<String?> fetchLocal(String photoId) async {
    fetched.add(photoId);
    return '/tmp/$photoId.jpg';
  }

  @override
  Future<Uint8List?> thumbnail(String photoId, {required int maxPx}) async =>
      Uint8List.fromList([7]);
}

PhotoItem _item(String id, {String name = '', PhotoKind? kind}) => PhotoItem(
  id: id,
  name: name,
  takenAtMs: Int64(0),
  kind: kind ?? .PHOTO_KIND_PHOTO,
);

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        captured = context;
        return const SizedBox();
      },
    ),
  );
  return captured;
}

void main() {
  test('a dragged photo keeps its phone name, never a folder', () {
    expect(
      PhotoDrag.fileName(_item('a', name: 'IMG_2041.jpg')),
      'IMG_2041.jpg',
    );
    expect(PhotoDrag.fileName(_item('a', name: '../../etc/x.jpg')), 'x.jpg');
    expect(PhotoDrag.fileName(_item('a', name: r'C:\a\b.png')), 'b.png');
    expect(PhotoDrag.fileName(_item('a')), 'Photo.jpg');
    expect(
      PhotoDrag.fileName(_item('a', kind: .PHOTO_KIND_VIDEO)),
      'Video.mp4',
    );
  });

  testWidgets('photos here already are dragged as files', (tester) async {
    final context = await _context(tester);
    final gallery = _Gallery()..copies['p0'] = '/saved/p0.jpg';
    final dragOut = _RecordingDragOut();

    await PhotoDrag.start(
      context,
      dragOut: dragOut,
      viewModel: gallery,
      items: [_item('p0')],
    );

    expect(dragOut.fileDrags, [
      ['/saved/p0.jpg'],
    ]);
    expect(dragOut.promisedDrags, isEmpty);
  });

  testWidgets('photos still on the phone are promised and fetched on drop', (
    tester,
  ) async {
    final context = await _context(tester);
    final gallery = _Gallery()..copies['p0'] = '/saved/p0.jpg';
    final dragOut = _RecordingDragOut();

    await tester.runAsync(
      () => PhotoDrag.start(
        context,
        dragOut: dragOut,
        viewModel: gallery,
        items: [
          _item('p0', name: 'IMG_1.jpg'),
          _item('p1', name: 'IMG_2.jpg'),
        ],
      ),
    );
    final promised = dragOut.promisedDrags.single;

    expect(promised.map((file) => file.name), ['IMG_1.jpg', 'IMG_2.jpg']);
    expect(promised.first.image, [7]);
    expect(gallery.fetched, isEmpty);
    expect(await promised.last.fetch(), '/tmp/p1.jpg');
    expect(gallery.fetched, ['p1']);
  });

  test('a drag outside a selection takes only that photo', () {
    final gallery = _Gallery();
    final first = _item('p0');

    expect(gallery.dragged(first), [first]);
  });
}
