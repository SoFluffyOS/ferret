// The shelf box at the bottom of the Mac popover: empty, with files, a
// phone photo, text and a link, five texts, with a selection, under the pointer, while
// something is dragged over it, with a missing file, with previews hidden,
// its list page, the floating panel a drag brings over other apps, and
// Settings → Shelf with the ways to reach it while dragging. Renders into temp/screens as `shelf_<name>_*.png`.
// Run from apps/ferret:
//
//   fvm flutter test test/screens/shelf_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

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

/// Fills the shelf with a few dropped things and two copies, kept since
/// Keep copies is on.
Future<void> fillShelf(WidgetTester tester, ShelfStore store) async {
  final viewModel = shelfViewModel(tester);
  await tester.runAsync(() async {
    await viewModel.setKeepCopies(true);
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

ShelfViewModel shelfViewModel(WidgetTester tester) =>
    tester.element(find.byType(ShelfBoxFrame).first).read<ShelfViewModel>();

/// The floating panel as it shows over another app: its size, its corner
/// and the system's shadow, on a plain desktop.
class _PanelPreview extends StatelessWidget {
  const _PanelPreview(this.viewModel);

  final ShelfViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF7A8794),
      child: Center(
        child: Container(
          width: ShelfPanelFrame.size.width,
          height: ShelfPanelFrame.size.height,
          clipBehavior: .antiAlias,
          decoration: ShapeDecoration(
            shape: Corners.shape(ShelfPanelFrame.radius),
            shadows: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ChangeNotifierProvider.value(
            value: viewModel,
            child: ShelfPanelFrame(onOpenList: () {}, onHover: (_) {}),
          ),
        ),
      ),
    );
  }
}

Future<void> _openPanel(WidgetTester tester, ScreenRig rig) async {
  await rig.settle(tester);
  await rig.open(tester, _PanelPreview(shelfViewModel(tester)));
}

/// The popover made taller for Settings → Clipboard, so the whole "While
/// you drag" section shows from its heading down, under the shelf.
const _tallPopover = CaptureSize('popover_tall', 380, 860);

/// Opens Settings → Clipboard at its end, where the shelf's section is.
Future<void> _openSettings(WidgetTester tester, ScreenRig rig) async {
  await rig.open(tester, const SettingsGroupPage(group: .clipboard));
  final scrollable = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(
    find.text('While you drag'),
    200,
    scrollable: scrollable,
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await rig.settle(tester);
}

Finder _tile(String label) => find.byWidgetPredicate(
  (widget) => widget is ShelfTile && widget.tooltip == label,
);

Future<void> _openList(WidgetTester tester, ScreenRig rig) async {
  await rig.settle(tester);
  await tester.tap(
    find.byWidgetPredicate(
      (widget) => widget is Tappable && widget.tooltip == 'Open the list',
    ),
  );
}

final _screens = <String, _Script>{
  'empty': (tester, rig, store) async {},
  'empty_drop_over': (tester, rig, store) async =>
      shelfViewModel(tester).hover(over: true),
  'items': (tester, rig, store) => fillShelf(tester, store),
  // Five copied texts: each tile shows its own first words.
  'texts': (tester, rig, store) async {
    await tester.runAsync(() async {
      await shelfViewModel(tester).setKeepCopies(true);
      for (final text in const [
        'ssh simon@192.168.1.20 -p 2222',
        'Meet at the north entrance, 7:30. Bring the tickets.',
        'https://github.com/simonpham/ferret/issues/42',
        'Wi-Fi password: blue-otter-1984',
        'Order #A-55102 ships on Friday',
      ]) {
        await store.keepText(
          text,
          isLink: text.startsWith('https://'),
          source: .copied,
        );
      }
    });
  },
  'drop_over': (tester, rig, store) async {
    await fillShelf(tester, store);
    await rig.settle(tester);
    shelfViewModel(tester).hover(over: true);
  },
  'selection': (tester, rig, store) async {
    await fillShelf(tester, store);
    await rig.settle(tester);
    await tester.tap(_tile('IMG_2041.png'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.tap(_tile('Trip to Da Lat'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  },
  'hover': (tester, rig, store) async {
    await fillShelf(tester, store);
    await rig.settle(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(_tile('Trip to Da Lat')));
  },
  'missing': (tester, rig, store) async {
    await fillShelf(tester, store);
    final folder = store.items.firstWhere(
      (item) => item.name == 'Trip to Da Lat',
    );
    await tester.runAsync(() async {
      Directory(folder.path).deleteSync();
      await store.refresh();
    });
  },
  'hidden': (tester, rig, store) => fillShelf(tester, store),
  'list': (tester, rig, store) async {
    await fillShelf(tester, store);
    await _openList(tester, rig);
    await rig.settle(tester);
    final viewModel = tester
        .element(find.byType(ShelfListFrame))
        .read<ShelfViewModel>();
    viewModel.select(viewModel.items[1].id);
  },
  'empty_list': (tester, rig, store) => _openList(tester, rig),
  'copies_list': (tester, rig, store) async {
    await tester.runAsync(() => shelfViewModel(tester).setKeepCopies(true));
    await tester.runAsync(
      () => store.keepText(
        'https://example.org/tickets/4471',
        isLink: true,
        source: .copied,
      ),
    );
    await _openList(tester, rig);
  },
  'hidden_list': (tester, rig, store) async {
    await fillShelf(tester, store);
    await _openList(tester, rig);
  },
  'panel_empty': (tester, rig, store) => _openPanel(tester, rig),
  'panel_items': (tester, rig, store) async {
    await fillShelf(tester, store);
    await _openPanel(tester, rig);
  },
  'panel_drop_over': (tester, rig, store) async {
    await fillShelf(tester, store);
    await _openPanel(tester, rig);
    shelfViewModel(tester).hover(over: true);
  },
  'settings': (tester, rig, store) => _openSettings(tester, rig),
  'settings_all_on': (tester, rig, store) async {
    final settings = ShelfSettings(
      ShellScope.read(
        tester.element(find.byType(ShelfBoxFrame).first),
      ).featureContext.engine.settings,
    );
    await tester.runAsync(() async {
      await settings.setBoxOnDrag(true);
      await settings.setShiftSummons(true);
      await settings.setShakeSensitivity(.high);
      await settings.setIgnoredApps(const [
        IgnoredApp(id: 'com.figma.Desktop', name: 'Figma'),
        IgnoredApp(id: 'com.apple.Safari', name: 'Safari'),
      ]);
    });
    await _openSettings(tester, rig);
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final brightness in Brightness.values) {
      final size = switch (name.startsWith('settings')) {
        true => _tallPopover,
        false => popover,
      };
      testWidgets('shelf $name ${brightness.name}', (tester) async {
        setScreen(tester, size, brightness);
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
          // This version ran here before, so no "Updated to" line on top.
          await rig.engine.settings.set(
            WhatsNew.seenVersionKey,
            rig.engine.device.appVersion,
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

          await rig.capture(tester, 'shelf_$name', size, brightness);

          await rig.dispose(tester);
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
