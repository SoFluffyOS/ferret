import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:transport/transport.dart';

/// Unpaired Ferret devices near you, in a window's device list, and what
/// features found near, such as a phone on a cable. Takes no room while
/// nothing is near. Pairing needs more room than a line here, so a device
/// opens Add a device; a feature's line does its one thing.
class SidebarNearbyFrame extends StatefulWidget {
  const SidebarNearbyFrame({super.key, required this.onPair});

  final VoidCallback onPair;

  @override
  State<SidebarNearbyFrame> createState() => _SidebarNearbyFrameState();
}

class _SidebarNearbyFrameState extends State<SidebarNearbyFrame> {
  late final NearbyViewModel _viewModel = NearbyViewModel(
    ShellScope.read(context).featureContext.engine,
    watch: false,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: FeatureChangesListener(
        features: scope.features,
        builder: (context) => _Nearby(
          onPair: widget.onPair,
          rows: [
            for (final feature in scope.features)
              ...feature.nearbyRows(context, scope.featureContext),
          ],
        ),
      ),
    );
  }
}

class _Nearby extends StatelessWidget {
  const _Nearby({required this.onPair, required this.rows});

  final VoidCallback onPair;
  final List<FeatureNearbyRow> rows;

  @override
  Widget build(BuildContext context) {
    final peers = context.select<NearbyViewModel, List<DiscoveredPeer>>(
      (viewModel) => viewModel.peers,
    );
    if (peers.isEmpty && rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;
    final pairStyle = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.accent,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.d12),
          child: SectionTitle(l10n.homeNearby),
        ),
        for (final peer in peers)
          SidebarRow(
            key: ValueKey(peer.deviceId),
            label: peer.announce.name,
            icon: deviceIconFor(
              peer.announce.formFactor,
              peer.announce.platform,
            ),
            trailing: Text(l10n.nearbyPair, style: pairStyle),
            onTap: onPair,
          ),
        for (final row in rows)
          SidebarRow(
            key: ValueKey(row.id),
            label: row.title,
            icon: row.icon,
            tooltip: row.detail,
            trailing: Text(row.actionLabel, style: pairStyle),
            onTap: row.onAction,
          ),
      ],
    );
  }
}
