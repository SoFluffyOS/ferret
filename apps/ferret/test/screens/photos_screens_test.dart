// Photos: a phone's photos on the Mac (grid, selection, the limited
// banner), the states that explain why there is nothing (not shared, no
// permission, empty), the Activity line after a save, and the page a
// computer's request opens on the phone. Renders into temp/screens as
// `photos_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/photos_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:photos/photos.dart';
import 'package:shell/shell.dart';

import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(WidgetTester tester, ScreenRig rig);

/// A phone's library with made-up pictures: soft gradients, one per photo.
class _SampleLibrary implements PhotoLibrary {
  _SampleLibrary(this.count, {this.accessNow = .full, this.firstName});

  final int count;
  final PhotoLibraryAccess accessNow;

  /// The newest photo's file name, such as a long one the title must fit.
  final String? firstName;
  final Map<String, Uint8List> _images = {};

  late final List<PhotoEntry> entries = [
    for (var index = 0; index < count; index++)
      PhotoEntry(
        id: 'p$index',
        takenAt: DateTime(2026, 11, 19, 9).subtract(Duration(hours: index * 5)),
        kind: switch (index % 7) {
          1 => PhotoEntryKind.screenshot,
          4 => PhotoEntryKind.video,
          _ => PhotoEntryKind.photo,
        },
        width: 1200,
        height: 1600,
        name: switch ((index, firstName)) {
          (0, final name?) => name,
          _ => 'IMG_${2041 + index}.jpg',
        },
      ),
  ];

  Future<void> paint() async {
    for (final (index, entry) in entries.indexed) {
      _images[entry.id] = await _gradient(index);
    }
  }

  @override
  bool get isSupported => true;

  @override
  Future<PhotoLibraryAccess> access() async => accessNow;

  @override
  Future<PhotoLibraryAccess> requestAccess() async => accessNow;

  @override
  Future<PhotoPage> list({String? cursor, int limit = 60}) async {
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, entries.length);
    return PhotoPage(
      entries.sublist(start, end),
      nextCursor: switch (end < entries.length) {
        true => '$end',
        false => null,
      },
    );
  }

  @override
  Future<Uint8List?> thumbnail(String id, {required int maxPx}) async =>
      _images[id];

  @override
  Future<String?> export(String id) async => null;

  @override
  Stream<PhotoEntry> get newScreenshots => const Stream.empty();

  @override
  Future<bool> openSettings() async => false;

  static Future<Uint8List> _gradient(int index) async {
    const side = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final hue = (index * 47) % 360;
    final top = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.62).toColor();
    final bottom = HSLColor.fromAHSL(
      1,
      ((hue + 40) % 360).toDouble(),
      0.6,
      0.38,
    ).toColor();
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, side, side),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          const ui.Offset(side, side),
          [top, bottom],
        ),
    );
    canvas.drawCircle(
      const ui.Offset(side * 0.7, side * 0.3),
      side * 0.12,
      ui.Paint()..color = const ui.Color(0xccffffff),
    );
    final image = await recorder.endRecording().toImage(
      side.toInt(),
      side.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List() ?? Uint8List(0);
  }
}

class _NoDragOut implements DragOut {
  const _NoDragOut();

  @override
  Future<bool> files(int viewId, List<String> paths) async => false;

  @override
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files) async =>
      false;

  @override
  Future<bool> text(int viewId, String text, {bool isLink = false}) async =>
      false;
}

class _Phone {
  _Phone(this.library) : feature = PhotosFeature(library: library);

  final _SampleLibrary library;
  final PhotosFeature feature;
}

Future<(String, PhotosFeature)> _pairPhone(
  WidgetTester tester,
  ScreenRig rig,
  _SampleLibrary library, {
  bool shares = true,
}) async {
  final phone = _Phone(library);
  await tester.runAsync(library.paint);
  final phoneId =
      await rig.pairConnectedPhone(
        tester,
        phoneFeatures: [PhotosFeatureUi(feature: phone.feature)],
        name: 'Pixel 7',
      ) ??
      '';
  if (shares) {
    await tester.runAsync(
      () => phone.feature.settings.setSharesWith(
        rig.engine.identity.deviceId,
        shared: true,
      ),
    );
  }

  await rig.settle(tester);
  return (phoneId, phone.feature);
}

Future<void> _openPhotos(WidgetTester tester, ScreenRig rig, String id) async {
  unawaited(rig.featureContext.openSection(id, PhotosFeatureUi.sectionId));
  // Each thumbnail goes to the phone and through the cache on disk: real
  // work that only moves while the test lets it.
  for (var round = 0; round < 8; round++) {
    await rig.settle(tester);
  }
}

Future<void> _openPreview(
  WidgetTester tester,
  ScreenRig rig,
  String phoneId,
) async {
  await _openPhotos(tester, rig, phoneId);
  await tester.tap(find.byKey(const ValueKey('p0')), warnIfMissed: false);
  for (var round = 0; round < 4; round++) {
    await rig.settle(tester);
  }
}

PhotosFeature _computer(ScreenRig rig) =>
    rig.app.features.whereType<PhotosFeatureUi>().single.feature;

final _screens = <String, _Script>{
  'grid': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(tester, rig, _SampleLibrary(17));
    await _openPhotos(tester, rig, phoneId);
  },
  'grid_drag': (tester, rig) async {
    rig.featureContext.dragOut = const _NoDragOut();
    final (phoneId, _) = await _pairPhone(tester, rig, _SampleLibrary(17));
    await _openPhotos(tester, rig, phoneId);
  },
  'device_page': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(tester, rig, _SampleLibrary(3));
    await rig.open(tester, DevicePage(deviceId: phoneId));
  },
  'selection': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(tester, rig, _SampleLibrary(17));
    await _openPhotos(tester, rig, phoneId);
    await rig.tapText(tester, 'Select');
    for (final id in ['p0', 'p2', 'p5']) {
      final tile = find.byKey(ValueKey(id));
      if (tile.evaluate().isEmpty) {
        continue;
      }

      await tester.tap(tile, warnIfMissed: false);
      await tester.pump();
    }
    await rig.settle(tester);
  },
  'limited': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(
      tester,
      rig,
      _SampleLibrary(5, accessNow: .limited),
    );
    await _openPhotos(tester, rig, phoneId);
  },
  'not_shared': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(
      tester,
      rig,
      _SampleLibrary(5),
      shares: false,
    );
    await _openPhotos(tester, rig, phoneId);
  },
  'no_permission': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(
      tester,
      rig,
      _SampleLibrary(5, accessNow: .denied),
    );
    await _openPhotos(tester, rig, phoneId);
  },
  'empty': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(tester, rig, _SampleLibrary(0));
    await _openPhotos(tester, rig, phoneId);
  },
  'preview': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(
      tester,
      rig,
      _SampleLibrary(3, firstName: 'nerver-seen-this-code.jpg'),
    );
    await _openPreview(tester, rig, phoneId);
  },
  'preview_long': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(
      tester,
      rig,
      _SampleLibrary(
        3,
        firstName: 'PXL_20261119_093512345.NIGHT.from-the-team-wiki-export.jpg',
      ),
    );
    await _openPreview(tester, rig, phoneId);
  },
  'saved_activity': (tester, rig) async {
    final (phoneId, _) = await _pairPhone(tester, rig, _SampleLibrary(3));
    final saves = _computer(rig).saves;
    saves
      ..add(
        PhotoSave(
          id: 'save.1',
          deviceId: phoneId,
          count: 3,
          startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          status: .done,
          fraction: 1,
        ),
      )
      ..add(
        PhotoSave(
          id: 'shot.1',
          deviceId: phoneId,
          count: 1,
          startedAt: DateTime.now(),
          isScreenshot: true,
          status: .done,
          fraction: 1,
        ),
      );
    await rig.settle(tester);
  },
};

/// Widget tests decode images only when real async work may run.
Future<void> _decodeImages(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget;
    if (image is! Image) {
      continue;
    }

    await tester.runAsync(() => precacheImage(image.image, element));
  }

  await tester.pump();
}

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  const window = CaptureSize('window', 1000, 720);
  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [popover, window]) {
      for (final brightness in Brightness.values) {
        testWidgets('photos $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = size.platform;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              return;
            }

            reportError?.call(details);
          };
          try {
            final rig = await ScreenRig.create(
              tester,
              features: [PhotosFeatureUi()],
              tipsDone: true,
            );
            await rig.show(tester);
            await script(tester, rig);
            await _decodeImages(tester);
            await rig.capture(tester, 'photos_$name', size, brightness);
            await rig.dispose(tester);
          } finally {
            FlutterError.onError = reportError;
            debugDisableShadows = true;
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}
