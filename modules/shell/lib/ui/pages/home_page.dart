import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/activity_page.dart';
import 'package:shell/ui/pages/device_page.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/pages/qr_pair_page.dart';
import 'package:shell/ui/pages/settings_page.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Home is your devices: what needs you, the devices with their actions,
/// who is nearby, and what just happened. Before anything is paired it is
/// the welcome.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// One list of devices near you, wherever it sits on the page, so a
  /// pairing under way survives the move when the first device pairs.
  static const _nearbyKey = ValueKey('nearby');

  /// How many finished things Activity shows before "See all".
  static const _activityShown = 3;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final hasDevices = context.select<EngineHost, bool>(
      (host) => host.devices.isNotEmpty,
    );
    final isPaused = context.select<PauseController, bool>(
      (controller) => controller.isPaused,
    );
    final l10n = context.shellL10n;

    return FerretPage(
      title: l10n.appName,
      backLabel: l10n.back,
      status: switch (isPaused) {
        true => l10n.homeStatusPaused,
        false => null,
      },
      actions: [
        Tappable(
          tooltip: l10n.homePairDevice,
          onTap: () => _push(context, const PairPage()),
          child: Padding(
            padding: EdgeInsets.all(Spacing.d6),
            child: Icon(
              LucideIcons.plus,
              size: Spacing.d20,
              color: context.palette.text,
            ),
          ),
        ),
        HomeMenu(onSettings: () => _push(context, const SettingsPage())),
      ],
      footer: const HomeFooter(),
      children: [
        const JoinedNoticesFrame(),
        if (hasDevices)
          for (final feature in scope.features)
            FeatureCardSlot(
              feature: feature,
              featureContext: scope.featureContext,
            ),
        if (!hasDevices)
          NearbyFrame(
            key: _nearbyKey,
            onPairWithCode: () => _pairWithCode(context),
            onCantSee: () => _push(context, const PairPage()),
          ),
        DevicesFrame(
          onOpen: (status) =>
              _push(context, DevicePage(deviceId: status.device.id)),
          onFix: (status) =>
              _push(context, DoctorPage(deviceId: status.device.id)),
        ),
        if (hasDevices) const NearbyFrame(key: _nearbyKey, watch: false),
        if (hasDevices) const StayConnectedCard(),
        if (hasDevices)
          ActivityFrame(
            limit: _activityShown,
            onSeeAll: () => _push(context, const ActivityPage()),
          ),
        if (hasDevices) const OffersCard(),
      ],
    );
  }

  /// A computer shows its code; a phone scans one, from Add a device.
  void _pairWithCode(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      _push(context, const PairPage());
      return;
    }

    _push(context, const QrPairPage());
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => page));
  }
}
