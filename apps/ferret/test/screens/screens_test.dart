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
import 'support/sample_activity.dart';
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

/// One screen: its file name and how to get there. [tall] screens are also saved at full length
/// (`<name>_full_<mode>.png`) so nothing below the fold is missed.
class Screen {
  const Screen(
    this.name,
    this.script, {
    this.tipsDone = false,
    this.sampleActivity = false,
    this.tall = false,
    this.phone = false,
    this.fullHeight = 2400,
  });

  final String name;
  final ScreenScript script;

  /// Whether the one-time tips were already seen, so Home shows without
  /// them.
  final bool tipsDone;

  /// Adds a feature that fills Activity with every kind of line.
  final bool sampleActivity;
  final bool tall;

  /// Runs as an Android phone paired with a computer (see [phoneFeatures]).
  final bool phone;

  /// Height of the full-length capture, in logical pixels.
  final double fullHeight;
}

const _offlineId = 'a1b2c3d4e5f60718';

final screens = <Screen>[
  Screen('home_empty', (tester, rig) async {}),
  Screen('home_empty_waited', (tester, rig) async {
    await tester.pump(const Duration(seconds: 11));
  }),
  Screen('home_offline', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
  }),
  Screen('home_offline_iphone', (tester, rig) async {
    await rig.addOfflinePhone(tester, name: 'iPhone', platform: .PLATFORM_IOS);
    await rig.settle(tester);
  }),
  Screen('home_reconnecting', (tester, rig) async {
    await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
    await rig.settle(tester);
    await rig.dropOthers(tester);
  }, tipsDone: true),
  Screen('activity_flaky_wifi', (tester, rig) async {
    await rig.addOfflinePhone(tester, name: 'Pixel 7');
    await tester.runAsync(() async {
      await rig.engine.feature<ClipboardFeature>()?.sendText('Gate B12');
      rig.engine.feature<DropFeature>()?.registry.put(
        Transfer(
          id: 'paused',
          direction: .outgoing,
          deviceId: _offlineId,
          deviceName: 'Pixel 7',
          files: const [
            TransferFile(name: 'holiday.mov', size: 1800 * 1024 * 1024),
          ],
          status: .failed,
          failure: .disconnected,
          bytesDone: 620 * 1024 * 1024,
          startedAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      );
    });
    await rig.open(tester, const ActivityPage());
  }),
  Screen('doctor_isolated', (tester, rig) async {
    await rig.addPhoneLastSeenAt(tester, host: '192.168.1.20');
    await rig.open(
      tester,
      DoctorPage(
        deviceId: _offlineId,
        doctorFor: (engine) => ConnectionDoctor(
          engine,
          isWindows: false,
          isLinux: false,
          interfaces: () async => [(name: 'en0', address: '192.168.1.5')],
          probe: (host, port, timeout) async => switch (host) {
            '192.168.1.1' => Reach.refused,
            _ => Reach.silent,
          },
        ),
      ),
    );
    await rig.settle(tester, real: const Duration(seconds: 1));
  }, tall: true),
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
  Screen('pair_qr', (tester, rig) async {
    await rig.open(tester, const QrPairPage());
  }),
  Screen('pair_other_ways', (tester, rig) async {
    await rig.open(tester, const OtherWaysPage());
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
  Screen('device_details', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.open(tester, const DevicePage(deviceId: _offlineId));
    await rig.tapText(tester, 'Details');
  }),
  Screen('device_forget', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.open(tester, const DevicePage(deviceId: _offlineId));
    await rig.tapText(tester, 'Forget Pixel 9');
  }),
  Screen('device_access', (tester, rig) async {
    final phoneId = await rig.pairConnectedPhone(
      tester,
      phoneFeatures: appFeatures(),
    );
    if (phoneId == null) {
      return;
    }

    await rig.engine.access.setAllowed(phoneId, 'clipboard', allowed: false);
    await rig.open(tester, DeviceAccessPage(deviceId: phoneId));
  }, tall: true),
  Screen('device_access_offline', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.engine.access.blockAll(_offlineId, ['mirroring', 'messages']);
    await rig.open(tester, const DeviceAccessPage(deviceId: _offlineId));
  }),
  Screen(
    'phone_device_connected',
    (tester, rig) async {
      final computerId = await rig.pairConnectedComputer(
        tester,
        computerFeatures: appFeatures(),
      );
      if (computerId == null) {
        return;
      }

      await rig.open(tester, DevicePage(deviceId: computerId));
    },
    phone: true,
    tall: true,
  ),
  Screen('settings', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.open(tester, const SettingsPage());
  }),
  Screen('settings_connected', (tester, rig) async {
    await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
    await rig.open(tester, const SettingsPage());
  }),
  Screen('phone_settings', (tester, rig) async {
    await rig.pairConnectedComputer(tester, computerFeatures: appFeatures());
    await rig.open(tester, const SettingsPage());
  }, phone: true),
  for (final group in SettingsGroup.values) ...[
    Screen('settings_group_${group.name}', (tester, rig) async {
      await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
      await rig.open(tester, SettingsGroupPage(group: group));
    }, tall: true),
    Screen(
      'phone_settings_group_${group.name}',
      (tester, rig) async {
        await rig.pairConnectedComputer(
          tester,
          computerFeatures: appFeatures(),
        );
        await rig.open(tester, SettingsGroupPage(group: group));
      },
      phone: true,
      tall: true,
    ),
  ],
  Screen('settings_advanced', (tester, rig) async {
    await rig.open(tester, const AdvancedSettingsPage());
  }),
  Screen('settings_about', (tester, rig) async {
    await rig.open(tester, const AboutPage());
  }),
  Screen('doctor_network', (tester, rig) async {
    await rig.open(tester, const DoctorPage());
    await rig.settle(tester, real: const Duration(seconds: 1));
  }),
  Screen('doctor', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.open(tester, const DoctorPage(deviceId: _offlineId));
    await rig.settle(tester, real: const Duration(seconds: 2));
  }, tall: true),
  Screen('connect', (tester, rig) async {
    await rig.open(tester, const ConnectPage());
  }),
  Screen('home_menu', (tester, rig) async {
    await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
    await rig.settle(tester);
    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await rig.settle(tester);
  }, tipsDone: true),
  Screen('home_paused', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await rig.settle(tester);
    await rig.tapText(tester, 'Pause syncing for 1 hour');
  }),
  Screen(
    'home_activity',
    (tester, rig) async {
      await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
      await rig.addOfflinePhone(tester, name: 'iPad');
      await rig.settle(tester);
    },
    tall: true,
    tipsDone: true,
    sampleActivity: true,
  ),
  Screen(
    'home_many_devices',
    (tester, rig) async {
      await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
      await rig.pairConnectedPhone(
        tester,
        phoneFeatures: appFeatures(),
        name: 'Galaxy Tab',
      );
      await rig.addOfflinePhone(tester, name: 'iPad');
      await rig.addOfflinePhone(
        tester,
        name: 'ThinkPad',
        id: 'b1b2c3d4e5f60718',
      );
      await rig.settle(tester);
    },
    tall: true,
    tipsDone: true,
  ),
  Screen(
    'activity',
    (tester, rig) async {
      await rig.pairConnectedPhone(tester, phoneFeatures: appFeatures());
      await rig.open(tester, const ActivityPage());
    },
    tipsDone: true,
    sampleActivity: true,
  ),
  Screen('activity_empty', (tester, rig) async {
    await rig.open(tester, const ActivityPage());
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
  Screen(
    'phone_notifications_apps',
    (tester, rig) async {
      await rig.open(tester, samplePicker(.APP_FILTER_ALL));
    },
    phone: true,
  ),
  Screen(
    'phone_notifications_apps_except',
    (tester, rig) async {
      await rig.open(tester, samplePicker(.APP_FILTER_ALL_EXCEPT));
    },
    phone: true,
    tall: true,
  ),
];

// Layout overflows seen in the captures (see capturedOverflows) are written
// to `temp/screens/overflows.txt` instead of failing the run: with real fonts
// they are findings, not harness bugs.
void main() {
  setUpAll(loadScreenFonts);
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File('${screensDirectory.path}/overflows.txt').writeAsString(
      switch (capturedOverflows.isEmpty) {
        true => 'No overflows.\n',
        false => '${capturedOverflows.toSet().join('\n')}\n',
      },
    );
  });

  for (final screen in screens) {
    for (final size in sizes) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('${screen.name} ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = size.platform;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            final message = details.exceptionAsString();
            if (message.contains('overflowed')) {
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
  CaptureSize size,
  Brightness brightness,
) async {
  final name = screen.name;
  final rig = await ScreenRig.create(
    tester,
    features: [
      ...switch (screen.phone) {
        true => phoneFeatures(),
        false => appFeatures(),
      },
      if (screen.sampleActivity) SampleActivityFeatureUi(),
    ],
    tipsDone: screen.tipsDone,
    asPhone: screen.phone,
  );
  await rig.show(tester);

  await screen.script(tester, rig);
  await rig.capture(tester, name, size, brightness);

  if (screen.tall && size == phone) {
    final full = CaptureSize(
      'full',
      size.width,
      screen.fullHeight,
      platform: size.platform,
    );
    setScreen(tester, full, brightness);
    await rig.settle(tester);
    await rig.capture(tester, name, full, brightness);
  }

  await rig.dispose(tester);
}
