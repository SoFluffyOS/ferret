// The shelf at the bottom of the Mac popover: empty, with files, a phone
// photo, text and a link, opened, while something is dragged over it, and
// with previews hidden. Renders into temp/screens as `shelf_<name>_*.png`.
// Run from apps/ferret:
//
//   fvm flutter test test/screens/shelf_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  ShelfStore store,
);

/// A picture to stand in for a photo: a sunset in three bands.
Future<List<int>> _picture(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final bands = [
    const ui.Color(0xFFF2A65A),
    const ui.Color(0xFFE76F51),
    const ui.Color(0xFF264653),
  ];
  for (final (index, color) in bands.indexed) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, height * index / 3, width.toDouble(), height / 3),
      ui.Paint()..color = color,
    );
  }
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes?.buffer.asUint8List() ?? const [];
}

/// Puts a document, a folder, a photo from the phone, a copied picture,
/// text and a link on the shelf, newest last.
Future<void> _fill(WidgetTester tester, ShelfStore store) async {
  await tester.runAsync(() async {
    final home = Directory(p.join(p.dirname(store.folder), 'home'))
      ..createSync(recursive: true);
    final report = File(p.join(home.path, 'Q3 report.pdf'))
      ..writeAsStringSync('%PDF');
    final folder = Directory(p.join(home.path, 'Trip to Da Lat'))..createSync();
    final dropped = Directory(p.join(home.path, 'ferret-drops', 'a1'))
      ..createSync(recursive: true);
    final photo = File(p.join(dropped.path, 'IMG_2041.png'))
      ..writeAsBytesSync(await _picture(240, 180));

    await store.keepFiles([report.path, folder.path], source: .dropped);
    await store.keepFiles([photo.path], source: .dropped);
    await store.keepText(
      'Meet at the north entrance, 7:30. Bring the tickets.',
      isLink: false,
      source: .copied,
    );
    await store.keepText(
      'https://example.org/tickets/4471',
      isLink: true,
      source: .copied,
    );
  });
}

final _screens = <String, _Script>{
  'empty': (tester, rig, store) async {},
  'items': (tester, rig, store) => _fill(tester, store),
  'drop_over': (tester, rig, store) async {
    final viewModel = tester
        .element(find.byType(ShelfBarFrame))
        .read<ShelfViewModel>();
    viewModel.hover(over: true);
  },
  'open': (tester, rig, store) async {
    await _fill(tester, store);
    await rig.settle(tester);
    await tester.tap(find.byType(ShelfBarFrame));
    await rig.settle(tester);
    final viewModel = tester
        .element(find.byType(ShelfListFrame))
        .read<ShelfViewModel>();
    viewModel.select(viewModel.items[1].id);
  },
  'hidden': (tester, rig, store) => _fill(tester, store),
  'hidden_open': (tester, rig, store) async {
    await _fill(tester, store);
    await rig.settle(tester);
    await tester.tap(find.byType(ShelfBarFrame));
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('shelf $name ${brightness.name}', (tester) async {
        setScreen(tester, popover, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = popover.platform;
        try {
          final hidden = name.startsWith('hidden');
          final features = [
            ...appFeatures(),
            ShelfFeatureUi(showsPreviewsFrom: (_) => !hidden),
          ];
          final rig = await ScreenRig.create(
            tester,
            features: features,
            tipsDone: true,
          );
          await rig.pairConnectedPhone(
            tester,
            phoneFeatures: phoneFeatures(),
          );
          await rig.show(tester);
          final store = features
              .whereType<ShelfFeatureUi>()
              .single
              .feature
              .store;
          if (store == null) {
            throw StateError('The shelf has no store.');
          }

          await script(tester, rig, store);
          // Pictures decode on real time: give them a few rounds.
          for (var round = 0; round < 3; round++) {
            await rig.settle(tester);
          }

          await rig.capture(tester, 'shelf_$name', popover, brightness);
          await rig.dispose(tester);
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
