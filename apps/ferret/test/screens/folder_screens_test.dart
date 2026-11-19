// Send folders: a folder on its way with its file count, a received folder
// with Open and Show in Finder, an older Ferret that can't take folders,
// and a device's Files with Choose a folder. Renders into temp/screens as
// `folder_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/folder_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:drop/drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(WidgetTester tester, ScreenRig rig);

const _megabyte = 1024 * 1024;

/// 340 photos of 10 MB in Photos and Photos/2024, the first [done] of
/// them across.
List<TransferFile> _photos({String root = 'Photos', String? at}) => [
  for (var index = 0; index < 340; index++)
    TransferFile(
      name: 'IMG_${1000 + index}.jpg',
      size: 10 * _megabyte,
      mime: 'image/jpeg',
      folder: switch (index < 200) {
        true => root,
        false => '$root/2024',
      },
      location: switch (at) {
        final base? => '$base/$root/IMG_${1000 + index}.jpg',
        null => null,
      },
    ),
];

Future<String> _phone(WidgetTester tester, ScreenRig rig) async =>
    await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    ) ??
    '';

Future<void> _put(WidgetTester tester, ScreenRig rig, String phoneId) =>
    tester.runAsync(() async {
      final registry = rig.engine.feature<DropFeature>()?.registry;
      registry
        ?..put(
          Transfer(
            id: 'old',
            direction: .outgoing,
            deviceId: phoneId,
            deviceName: 'Pixel 7',
            files: _photos(root: 'Scans', at: '/Users/me/Documents'),
            status: .failed,
            failure: .foldersUnsupported,
            startedAt: DateTime.now().subtract(const Duration(minutes: 9)),
          ),
        )
        ..put(
          Transfer(
            id: 'received',
            direction: .incoming,
            deviceId: phoneId,
            deviceName: 'Pixel 7',
            files: _photos(
              root: 'Camera (2)',
              at: '/Users/me/Downloads/Ferret',
            ),
            status: .done,
            bytesDone: 3400 * _megabyte,
            startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
          ),
        )
        ..put(
          Transfer(
            id: 'sending',
            direction: .outgoing,
            deviceId: phoneId,
            deviceName: 'Pixel 7',
            files: _photos(at: '/Users/me/Pictures'),
            status: .transferring,
            bytesDone: 1205 * _megabyte,
            bytesPerSecond: 42.0 * _megabyte,
            skipped: 2,
            startedAt: DateTime.now(),
          ),
        );
    });

final _screens = <String, _Script>{
  'activity': (tester, rig) async {
    final phoneId = await _phone(tester, rig);
    await _put(tester, rig, phoneId);
    await rig.open(tester, const ActivityPage());
  },
  'files': (tester, rig) async {
    final phoneId = await _phone(tester, rig);
    await _put(tester, rig, phoneId);
    await rig.open(
      tester,
      DeviceSectionPage(
        deviceId: phoneId,
        sectionId: DropFeatureUi.sectionId,
      ),
    );
  },
};

void main() {
  setUpAll(loadScreenFonts);
  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [popover, phone]) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('folder $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = size.platform;
          try {
            final rig = await ScreenRig.create(
              tester,
              features: appFeatures(),
              name: 'MacBook Air',
              tipsDone: true,
            );
            await rig.show(tester);
            await script(tester, rig);
            await rig.capture(tester, 'folder_$name', size, brightness);
            await rig.dispose(tester);
          } finally {
            debugDisableShadows = true;
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}
