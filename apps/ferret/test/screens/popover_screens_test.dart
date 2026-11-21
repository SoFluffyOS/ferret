// The Mac popover as someone sees it who opens it fifty times a day: Home
// with no, one and three devices over an empty or a full shelf, a device's
// page, Settings and Activity with the shelf under them, and the shelf
// reached from the keyboard. Renders into temp/screens as
// `popover_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/popover_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'shelf_screens_test.dart' show fillShelf;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

enum _Devices { none, one, three }

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  String? phoneId,
);

class _Screen {
  const _Screen(this.devices, {this.full = false, this.script});

  final _Devices devices;
  final bool full;
  final _Script? script;
}

Finder _tile(String label) => find.byWidgetPredicate(
  (widget) => widget is ShelfTile && widget.tooltip == label,
);

/// Something dragged off the shelf, resting over the card of [device].
void _dragOver(WidgetTester tester, String device) {
  final over = tester.getCenter(find.text(device).first);
  tester
      .element(find.byType(DeviceTile).first)
      .read<OsDropViewModel>()
      .enter(over, fileCount: 1, fromApp: true);
}

final _screens = <String, _Screen>{
  'none_empty': const _Screen(.none),
  'none_full': const _Screen(.none, full: true),
  'one_empty': const _Screen(.one),
  'one_full': const _Screen(.one, full: true),
  'three_empty': const _Screen(.three),
  'three_full': const _Screen(.three, full: true),
  'device_full': _Screen(
    .one,
    full: true,
    script: (tester, rig, phoneId) async {
      if (phoneId != null) {
        await rig.open(tester, DevicePage(deviceId: phoneId));
      }
    },
  ),
  'settings_full': _Screen(
    .one,
    full: true,
    script: (tester, rig, _) => rig.open(tester, const SettingsPage()),
  ),
  'activity_full': _Screen(
    .one,
    full: true,
    script: (tester, rig, _) => rig.open(tester, const ActivityPage()),
  ),
  // A shelf item dragged over a device's card, and over an offline one.
  'drop_device': _Screen(
    .three,
    full: true,
    script: (tester, rig, _) async => _dragOver(tester, 'Pixel 9'),
  ),
  'drop_device_offline': _Screen(
    .three,
    full: true,
    script: (tester, rig, _) async => _dragOver(tester, 'iPhone 15'),
  ),
  // Clicked a tile, then moved on with the arrow keys.
  'keys_arrows': _Screen(
    .one,
    full: true,
    script: (tester, rig, _) async {
      await tester.tap(_tile('IMG_2041.png'));
      await rig.settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    },
  ),
  // Moved down the devices with the arrow keys.
  'keys_devices': _Screen(
    .three,
    full: true,
    script: (tester, rig, _) async {
      for (var press = 0; press < 2; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
    },
  ),
  // Tabbed from the page into the shelf.
  'keys_tab': _Screen(
    .one,
    full: true,
    script: (tester, rig, _) async {
      // The real popover sets this up with its keys; the harness has no
      // menubar.
      PopoverKeysFrame.letTabLeavePages(rig.navigator);
      for (var press = 0; press < 40; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        final focus = FocusManager.instance.primaryFocus;
        if (focus?.debugLabel == 'shelf box') {
          break;
        }
      }
    },
  ),
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: screen) in _screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('popover $name ${brightness.name}', (tester) async {
        setScreen(tester, popover, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = popover.platform;
        try {
          final features = [...appFeatures(), ShelfFeatureUi()];
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
          String? phoneId;
          if (screen.devices != .none) {
            phoneId = await rig.pairConnectedPhone(
              tester,
              phoneFeatures: phoneFeatures(),
            );
          }

          if (screen.devices == .three) {
            await rig.pairConnectedComputer(
              tester,
              computerFeatures: appFeatures(),
              name: 'Studio PC',
              platform: .PLATFORM_WINDOWS,
            );
            await rig.addOfflinePhone(
              tester,
              name: 'iPhone 15',
              id: 'f0e1d2c3b4a59687',
              platform: .PLATFORM_IOS,
            );
          }

          await rig.show(tester);
          final store = features
              .whereType<ShelfFeatureUi>()
              .single
              .feature
              .store;
          if (store == null) {
            throw StateError('The shelf has no store.');
          }

          if (screen.full) {
            await fillShelf(tester, store);
          }

          for (var round = 0; round < 3; round++) {
            await rig.settle(tester);
          }

          await screen.script?.call(tester, rig, phoneId);
          for (var round = 0; round < 3; round++) {
            await rig.settle(tester);
          }

          await rig.capture(tester, 'popover_$name', popover, brightness);
          await rig.dispose(tester);
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
