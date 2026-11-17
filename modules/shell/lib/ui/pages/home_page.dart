import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/device_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/pages/settings_page.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:transport/transport.dart';

/// Devices, nearby devices, and each feature's card.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final palette = context.palette;
    final cards = [
      for (final feature in scope.features)
        ?feature.buildHomeCard(context, scope.featureContext),
    ];

    return FerretPage(
      title: l10n.appName,
      backLabel: l10n.back,
      actions: [
        Tappable(
          tooltip: l10n.homePairDevice,
          onTap: () => _openPairing(context),
          child: Padding(
            padding: EdgeInsets.all(Spacing.d6),
            child: Icon(
              LucideIcons.plus,
              size: Spacing.d20,
              color: palette.text,
            ),
          ),
        ),
        Tappable(
          tooltip: l10n.settingsTitle,
          onTap: () => _push(context, const SettingsPage()),
          child: Padding(
            padding: EdgeInsets.all(Spacing.d6),
            child: Icon(
              LucideIcons.settings,
              size: Spacing.d20,
              color: palette.text,
            ),
          ),
        ),
      ],
      children: [
        for (final card in cards)
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d8),
            child: card,
          ),
        DevicesFrame(
          onOpen: (status) => _openDevice(context, status),
          onPair: () => _openPairing(context),
        ),
        NearbyFrame(onPair: (peer) => _pairNearby(context, peer)),
      ],
    );
  }

  void _openPairing(BuildContext context) => _push(context, const PairPage());

  void _pairNearby(BuildContext context, DiscoveredPeer peer) =>
      _push(context, PairPage(initialAddress: '${peer.host}:${peer.port}'));

  void _openDevice(BuildContext context, DeviceStatus status) =>
      _push(context, DevicePage(deviceId: status.device.id));

  void _push(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => page));
  }
}
