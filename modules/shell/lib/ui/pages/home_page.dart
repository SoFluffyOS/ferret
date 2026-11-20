import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/activity_page.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/pages/qr_pair_page.dart';
import 'package:shell/ui/pages/scan_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
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

    return KeyboardLines(
      child: FerretPage(
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
          HomeMenu(
            onSettings: () => context.read<WindowNavRegistry>().open(
              const SettingsDestination(),
            ),
          ),
        ],
        footer: const HomeFooter(),
        width: switch (hasDevices) {
          true => .page,
          false => .narrow,
        },
        children: [
          const LocalNetworkCard(),
          const NeedsYouFrame(),
          const JoinedNoticesFrame(),
          const SuccessorsFrame(),
          // Where there is a device list, the line sits under it, so it
          // shows whatever the pane is on.
          if (!WindowLayout.splits(context)) const WhatsNewFrame(),
          if (hasDevices)
            for (final feature in scope.features)
              FeatureCardSlot(
                feature: feature,
                featureContext: scope.featureContext,
              ),
          if (!hasDevices)
            NearbyFrame(
              key: _nearbyKey,
              onPairWithCode: () => unawaited(_pairWithCode(context)),
              onCantSee: () => _push(context, const DoctorPage()),
            ),
          DevicesFrame(
            onOpen: (status) => context.read<WindowNavRegistry>().open(
              DeviceDestination(status.device.id),
            ),
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
      ),
    );
  }

  /// A computer shows its code. A phone opens the camera straight away and
  /// pairs on Add a device once it has read a code.
  Future<void> _pairWithCode(BuildContext context) async {
    final isPhone = switch (defaultTargetPlatform) {
      .android || .iOS => true,
      _ => false,
    };
    if (!isPhone) {
      _push(context, const QrPairPage());
      return;
    }

    final navigator = Navigator.of(context);
    final link = await navigator.push(ferretRoute<String>(const ScanPage()));
    if (link == null) {
      return;
    }

    unawaited(navigator.push(ferretRoute<void>(PairPage(link: link))));
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(ferretRoute<void>(page));
  }
}
