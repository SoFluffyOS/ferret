import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;

import 'helpers/fake_drag_out.dart';

void main() {
  late Directory root;
  late ShelfStore store;
  late FakeDragOut dragOut;
  late Set<String> hiddenDevices;

  ShelfViewModel viewModelOf() => ShelfViewModel(
    localDeviceId: 'mac',
    showsPreviewsFrom: (deviceId) => !hiddenDevices.contains(deviceId),
    dragOut: dragOut,
  )..attach(store);

  setUp(() async {
    root = Directory.systemTemp.createTempSync('shelf_vm_test');
    store = ShelfStore(p.join(root.path, 'shelf'));
    await store.load();
    dragOut = FakeDragOut();
    hiddenDevices = {};
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('what is dropped on it is kept until removed', () async {
    final viewModel = viewModelOf();
    final file = File(p.join(root.path, 'a.txt'))..writeAsStringSync('a');

    viewModel.hover(over: true);
    expect(viewModel.isDropOver, isTrue);
    await viewModel.takeFiles([file.path]);
    await viewModel.takeText('https://example.com', isLink: false);
    await pumpEventQueue();

    expect(viewModel.isDropOver, isFalse);
    expect(
      [for (final item in viewModel.items) item.kind],
      [
        ShelfKind.link,
        ShelfKind.file,
      ],
    );
    expect(
      viewModel.items.every((item) => item.source == .dropped),
      isTrue,
    );
  });

  test('one text drags as text, a link as a link, more as files', () async {
    final viewModel = viewModelOf();
    await store.keepText('hello there', isLink: false, source: .copied);
    await store.keepText('https://example.com', isLink: true, source: .copied);
    await pumpEventQueue();
    final [link, text] = viewModel.items;

    await viewModel.drag(1, [text]);
    await viewModel.drag(1, [link]);
    await viewModel.drag(1, viewModel.items);

    expect(dragOut.texts, [
      ('hello there', false),
      ('https://example.com', true),
    ]);
    expect(dragOut.fileDrags.single, [link.path, text.path]);
  });

  test('a drag takes the selection when it starts on it', () async {
    final viewModel = viewModelOf();
    for (final name in ['a', 'b', 'c']) {
      await store.keepText(name, isLink: false, source: .copied);
    }
    await pumpEventQueue();
    final [c, b, a] = viewModel.items;

    viewModel.select(c.id);
    viewModel.select(a.id, extend: true);
    expect(viewModel.selected, {c.id, b.id, a.id});

    viewModel.select(b.id, toggle: true);
    expect(viewModel.dragged(c), [c, a]);
    expect(viewModel.dragged(b), [b]);
  });

  test('hidden previews hide everything, or one device', () async {
    final viewModel = viewModelOf();
    await store.keepText('mine', isLink: false, source: .copied);
    await store.keepText(
      'from the phone',
      isLink: false,
      source: .copied,
      fromDeviceId: 'pixel',
    );
    await pumpEventQueue();
    final [phone, mine] = viewModel.items;

    hiddenDevices = {'pixel'};
    expect(viewModel.isHidden, isFalse);
    expect(viewModel.hides(phone), isTrue);
    expect(viewModel.hides(mine), isFalse);

    await viewModel.drag(1, [phone]);
    expect(dragOut.texts, isEmpty);

    hiddenDevices = {'mac'};
    expect(viewModel.isHidden, isTrue);
    expect(viewModel.hides(mine), isTrue);
  });

  test('removing a selected item drops it from the selection', () async {
    final viewModel = viewModelOf();
    await store.keepText('a', isLink: false, source: .copied);
    await pumpEventQueue();
    final item = viewModel.items.single;

    viewModel.select(item.id);
    await viewModel.removeSelected();
    await pumpEventQueue();

    expect(viewModel.items, isEmpty);
    expect(viewModel.selected, isEmpty);
  });

  test('copies wait for the shelf to be ready, files by reference', () async {
    final feature = ShelfFeature();
    final file = File(p.join(root.path, 'copied.pdf'))..writeAsStringSync('');

    final keeping = feature.keepCopy(text: 'copied.pdf', files: [file.path]);
    feature.use(store);
    await keeping;
    await feature.keepCopy(text: 'https://example.com');
    await feature.keepCopy(text: 'from phone', fromDeviceId: 'pixel');

    expect(
      [for (final item in store.items) item.kind],
      [
        ShelfKind.text,
        ShelfKind.link,
        ShelfKind.file,
      ],
    );
    expect(store.items.last.path, file.path);
    expect(store.items.first.fromDeviceId, 'pixel');
    expect(feature.isAvailable, isFalse);
  });
}
