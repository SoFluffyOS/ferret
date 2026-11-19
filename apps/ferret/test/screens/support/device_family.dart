// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';

import 'screen_harness.dart';

/// One of the persona's offline devices, straight in the trust store.
class FamilyDevice {
  const FamilyDevice(
    this.id,
    this.name,
    this.platform,
    this.formFactor,
    this.away,
  );

  final String id;
  final String name;
  final Platform platform;
  final FormFactor formFactor;

  /// How long ago it was last seen.
  final Duration away;
}

const workIphoneId = '1a2b3c4d5e6f7a8b';
const desktopId = '2b3c4d5e6f7a8b9c';
const thinkpadId = '3c4d5e6f7a8b9cad';
const oldPixelId = '99aa88bb77cc3f2a';
const ipadId = '4d5e6f7a8b9cadbe';

/// A work iPhone, a Windows desktop, a Linux laptop, an old Pixel 7 that
/// shares its name with the one in use, and an iPad left in a drawer.
const offlineFamily = [
  FamilyDevice(
    workIphoneId,
    'iPhone',
    .PLATFORM_IOS,
    .FORM_FACTOR_PHONE,
    Duration(hours: 3),
  ),
  FamilyDevice(
    desktopId,
    'DESKTOP-7Q2KD1',
    .PLATFORM_WINDOWS,
    .FORM_FACTOR_DESKTOP,
    Duration(minutes: 20),
  ),
  FamilyDevice(
    thinkpadId,
    'ThinkPad X1',
    .PLATFORM_LINUX,
    .FORM_FACTOR_LAPTOP,
    Duration(days: 5),
  ),
  FamilyDevice(
    oldPixelId,
    'Pixel 7',
    .PLATFORM_ANDROID,
    .FORM_FACTOR_PHONE,
    Duration(days: 45),
  ),
  FamilyDevice(
    ipadId,
    'iPad',
    .PLATFORM_IOS,
    .FORM_FACTOR_TABLET,
    Duration(days: 40),
  ),
];

/// Pairs the persona's seven devices: a Pixel 7 and a Galaxy Tab that are
/// connected, and [offlineFamily]. Returns the connected Pixel's id.
Future<String?> pairFamily(
  WidgetTester tester,
  ScreenRig rig, {
  required List<FeatureUi> Function() phoneFeatures,
}) async {
  final pixelId = await rig.pairConnectedPhone(
    tester,
    phoneFeatures: phoneFeatures(),
    name: 'Pixel 7',
  );
  await rig.pairConnectedPhone(
    tester,
    phoneFeatures: phoneFeatures(),
    name: 'Galaxy Tab S9',
  );
  await tester.runAsync(() async {
    final now = DateTime.now();
    for (final member in offlineFamily) {
      await rig.engine.trustStore.save(
        TrustedDevice(
          id: member.id,
          name: member.name,
          platform: member.platform,
          formFactor: member.formFactor,
          publicKey: Uint8List(32),
          pairedAt: now.subtract(const Duration(days: 300)),
          lastSeen: now.subtract(member.away),
        ),
      );
    }
  });
  await rig.settle(tester);
  return pixelId;
}

/// Two more offline devices, so the window's list gets its search field.
Future<void> addMoreFamily(WidgetTester tester, ScreenRig rig) async {
  await tester.runAsync(() async {
    final now = DateTime.now();
    for (final (id, name) in [
      ('5e6f7a8b9cadbecf', "Mum's Pixel 6a"),
      ('6f7a8b9cadbecfd0', 'Living room PC'),
    ]) {
      await rig.engine.trustStore.save(
        TrustedDevice(
          id: id,
          name: name,
          platform: .PLATFORM_ANDROID,
          formFactor: .FORM_FACTOR_PHONE,
          publicKey: Uint8List(32),
          pairedAt: now.subtract(const Duration(days: 100)),
          lastSeen: now.subtract(const Duration(days: 8)),
        ),
      );
    }
  });
  await rig.settle(tester);
}

/// Activity from several devices at once: two phones' notifications, a
/// file from the desktop, a copy from the work iPhone.
class FamilyActivityFeatureUi extends FeatureUi {
  @override
  String get featureId => 'screens.family';

  @override
  final Feature feature = _FamilyFeature();

  @override
  String title(BuildContext context) => 'Family';

  @override
  IconData get icon => LucideIcons.users;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    final now = DateTime.now();
    final pixel = feature.engine.devices
        .where((status) => status.device.ownName == 'Pixel 7')
        .where((status) => status.isConnected)
        .firstOrNull
        ?.device;
    final pixelName = pixel?.name ?? 'Pixel 7';

    return [
      ActivityItem(
        id: 'n1',
        icon: LucideIcons.bell,
        title: '3 notifications from $pixelName',
        detail: 'Signal: Ana: on my way',
        deviceId: pixel?.id,
        at: now.subtract(const Duration(minutes: 1)),
        onTap: () {},
      ),
      ActivityItem(
        id: 'n2',
        icon: LucideIcons.bell,
        title: '5 notifications from iPhone',
        detail: 'Slack: standup moved to 10:30',
        deviceId: workIphoneId,
        at: now.subtract(const Duration(minutes: 3)),
        onTap: () {},
      ),
      ActivityItem(
        id: 'clip',
        icon: LucideIcons.clipboard,
        title: 'Copied on iPhone',
        detail: '“JIRA-4182”',
        deviceId: workIphoneId,
        at: now.subtract(const Duration(minutes: 6)),
      ),
      ActivityItem(
        id: 'file',
        icon: LucideIcons.arrowDown,
        title: 'report.xlsx from DESKTOP-7Q2KD1',
        detail: 'Saved to Downloads › Ferret',
        deviceId: desktopId,
        at: now.subtract(const Duration(minutes: 22)),
      ),
      ActivityItem(
        id: 'n3',
        icon: LucideIcons.bell,
        title: 'Notification from $pixelName',
        detail: 'Photos: 12 new memories',
        deviceId: pixel?.id,
        at: now.subtract(const Duration(minutes: 40)),
        onTap: () {},
      ),
      ActivityItem(
        id: 'tab',
        icon: LucideIcons.globe,
        title: 'Continue “Recipes” from Galaxy Tab S9',
        detail: 'example.org',
        at: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }
}

class _FamilyFeature extends Feature {
  @override
  String get id => 'screens.family';

  @override
  Future<Null> onEnvelope(Session session, Envelope envelope) async => null;
}
