// Screenshot harness: renders the real app with a real engine and saves PNGs
// to temp/screens for UX review. Run from apps/ferret:
//
//   fvm flutter test test/screens
//
// See temp/screens/AUDIT.md for what each screen is and what was found.
// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:io';

import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:find/find.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:iphone/iphone.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/media.dart';
import 'package:messages/messages.dart';
import 'package:mirroring/mirroring.dart';
import 'package:notifications/notifications.dart';
import 'package:power/power.dart';
import 'package:remote_input/remote_input.dart';
import 'package:shell/shell.dart';

import 'support/phone_fakes.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

/// The same list as `lib/main.dart`.
List<FeatureUi> appFeatures() => [
  CallsFeatureUi(),
  ClipboardFeatureUi(),
  DropFeatureUi(),
  FindFeatureUi(),
  HandoffFeatureUi(),
  IphoneFeatureUi(),
  MediaFeatureUi(),
  MessagesFeatureUi(),
  MirroringFeatureUi(),
  NotificationsFeatureUi(),
  PowerFeatureUi(),
  RemoteInputFeatureUi(),
];

/// The app as an Android phone would build it, as far as a macOS host
/// allows: notifications and messages get fake phone sources so their setup
/// offers show. Everything that checks `Platform.isAndroid` still renders
/// its computer variant.
List<FeatureUi> phoneFeatures() => [
  for (final feature in appFeatures())
    switch (feature.featureId) {
      'notifications' => NotificationsFeatureUi.withFeature(
        NotificationsFeature(source: OffNotificationSource()),
        access: OffNotificationSource(),
      ),
      'messages' => MessagesFeatureUi.withFeature(
        MessagesFeature(source: OffSmsSource()),
      ),
      _ => feature,
    },
];

typedef ScreenScript = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
);

/// One screen: its file name, how to get there, and whether it runs before
/// onboarding is done. [tall] screens are also saved at full length
/// (`<name>_full_<mode>.png`) so nothing below the fold is missed.
class Screen {
  const Screen(
    this.name,
    this.script, {
    this.onboarded = true,
    this.tall = false,
    this.phone = false,
    this.fullHeight = 2400,
  });

  final String name;
  final ScreenScript script;
  final bool onboarded;
  final bool tall;

  /// Runs as an Android phone paired with a computer (see [phoneFeatures]).
  final bool phone;

  /// Height of the full-length capture, in logical pixels.
  final double fullHeight;
}

const _offlineId = 'a1b2c3d4e5f60718';

final screens = <Screen>[
  Screen('onboard_1_welcome', (tester, rig) async {}, onboarded: false),
  Screen('onboard_2_name', (tester, rig) async {
    await rig.tapText(tester, 'Get started');
  }, onboarded: false),
  Screen(
    'onboard_3_pair',
    (tester, rig) async {
      await rig.tapText(tester, 'Get started');
      await rig.tapText(tester, 'Continue');
    },
    onboarded: false,
    tall: true,
  ),
  Screen(
    'onboard_3b_more_ways',
    (tester, rig) async {
      await rig.tapText(tester, 'Get started');
      await rig.tapText(tester, 'Continue');
      await rig.tapText(tester, "Can't see your device?");
    },
    onboarded: false,
    tall: true,
  ),
  Screen('onboard_4_ready_later', (tester, rig) async {
    await rig.tapText(tester, 'Get started');
    await rig.tapText(tester, 'Continue');
    await rig.tapText(tester, 'Do this later');
  }, onboarded: false),
  Screen('onboard_4_ready_paired', (tester, rig) async {
    await rig.tapText(tester, 'Get started');
    await rig.tapText(tester, 'Continue');
    await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
    await rig.settle(tester);
  }, onboarded: false),
  Screen('home_empty', (tester, rig) async {}),
  Screen('home_offline', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
  }),
  Screen('home_connected', (tester, rig) async {
    await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
    await rig.settle(tester);
  }, tall: true),
  Screen('home_nearby', (tester, rig) async {
    await rig.addNearby(tester, name: 'Pixel 9');
    await rig.addNearby(
      tester,
      name: 'Simon’s ThinkPad',
      platform: .PLATFORM_LINUX,
      formFactor: .FORM_FACTOR_LAPTOP,
    );
  }),
  Screen('home_connected_nearby', (tester, rig) async {
    await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
    await rig.addNearby(
      tester,
      name: 'iPad',
      platform: .PLATFORM_IOS,
      formFactor: .FORM_FACTOR_TABLET,
    );
    await rig.settle(tester);
  }, tall: true),
  Screen('pair_code', (tester, rig) async {
    await rig.startNearby(tester);
    await rig.tapText(tester, 'Pair');
  }),
  Screen('pair_code_confirmed', (tester, rig) async {
    await rig.startNearby(tester);
    await rig.tapText(tester, 'Pair');
    await rig.tapText(tester, 'They match');
  }),
  Screen('pair_request', (tester, rig) async {
    final other = await rig.startNearby(
      tester,
      alreadyPairedWith: ['iPad', 'ThinkPad'],
    );
    if (other == null) {
      return;
    }

    await tester.runAsync(() async {
      unawaited(
        other.pairWithAddress(
          '127.0.0.1',
          rig.engine.port,
          onCode: (_) => true,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await rig.settle(tester);
  }),
  Screen('pair', (tester, rig) async {
    await rig.open(tester, const PairPage());
  }),
  Screen('pair_nearby', (tester, rig) async {
    await rig.addNearby(tester, name: 'Pixel 9');
    await rig.open(tester, const PairPage());
  }),
  Screen('pair_cant_see', (tester, rig) async {
    await rig.open(tester, const PairPage());
    await rig.tapText(tester, "Can't see your device?");
  }, tall: true),
  Screen('device_connected', (tester, rig) async {
    final phoneId = await rig.pairConnectedPhone(
      tester,
      phoneFeatures: appFeatures(),
    );
    if (phoneId == null) {
      return;
    }

    await rig.open(tester, DevicePage(deviceId: phoneId));
  }, tall: true),
  Screen('device_offline', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.open(tester, const DevicePage(deviceId: _offlineId));
  }),
  Screen(
    'settings',
    (tester, rig) async {
      await rig.addOfflinePhone(tester);
      await rig.open(tester, const SettingsPage());
    },
    tall: true,
    fullHeight: 4400,
  ),
  Screen('doctor', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.open(tester, const DoctorPage(deviceId: _offlineId));
    await rig.settle(tester, real: const Duration(seconds: 2));
  }, tall: true),
  Screen('connect', (tester, rig) async {
    await rig.open(tester, const ConnectPage());
  }),
  Screen('pause_dialog', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
    await tester.tap(find.byIcon(LucideIcons.pause));
    await rig.settle(tester);
  }),
  Screen(
    'phone_turn_on_more',
    (tester, rig) async {
      await rig.pairConnectedComputer(tester, computerFeatures: appFeatures());
      await rig.settle(tester);
    },
    phone: true,
    tall: true,
  ),
  Screen(
    'phone_messages_setup',
    (tester, rig) async {
      await rig.pairConnectedComputer(tester, computerFeatures: appFeatures());
      await rig.settle(tester);
      await rig.openOffer(tester, 'messages');
    },
    phone: true,
    tall: true,
  ),
  Screen(
    'phone_notifications_setup',
    (tester, rig) async {
      await rig.pairConnectedComputer(tester, computerFeatures: appFeatures());
      await rig.settle(tester);
      await rig.openOffer(tester, 'notifications');
    },
    phone: true,
    tall: true,
  ),
];

/// Layout overflows seen while capturing, written to
/// `temp/screens/overflows.txt` instead of failing the run: with real fonts
/// they are findings, not harness bugs.
final _overflows = <String>[];

void main() {
  setUpAll(loadScreenFonts);
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File('${screensDirectory.path}/overflows.txt').writeAsString(
      switch (_overflows.isEmpty) {
        true => 'No overflows.\n',
        false => '${_overflows.toSet().join('\n')}\n',
      },
    );
  });

  for (final screen in screens) {
    for (final size in sizes) {
      for (final brightness in Brightness.values) {
        testWidgets('${screen.name} ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            final message = details.exceptionAsString();
            if (message.contains('overflowed')) {
              final widget = details.informationCollector?.call().firstOrNull;
              _overflows.add(
                '${screen.name} ${size.name} ${brightness.name}: '
                '${message.split('\n').first} ($widget)',
              );
              return;
            }

            reportError?.call(details);
          };
          try {
            await _run(tester, screen, size, brightness);
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

Future<void> _run(
  WidgetTester tester,
  Screen screen,
  ScreenSize size,
  Brightness brightness,
) async {
  final name = screen.name;
  final rig = await ScreenRig.create(
    tester,
    features: switch (screen.phone) {
      true => phoneFeatures(),
      false => appFeatures(),
    },
    onboarded: screen.onboarded,
    asPhone: screen.phone,
  );
  await rig.show(tester);

  await screen.script(tester, rig);
  await rig.capture(tester, name, size, brightness);

  if (screen.tall && size == phone) {
    setScreen(tester, ScreenSize('full', 390, screen.fullHeight), brightness);
    await rig.settle(tester);
    await rig.capture(
      tester,
      name,
      ScreenSize('full', 390, screen.fullHeight),
      brightness,
    );
  }

  await rig.dispose(tester);
}
