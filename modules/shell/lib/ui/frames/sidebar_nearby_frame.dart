import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:transport/transport.dart';

/// Unpaired Ferret devices near you, in a window's device list. Takes no
/// room while nobody is near. Pairing needs more room than a line here, so
/// each one opens Add a device.
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
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: _Nearby(onPair: widget.onPair),
    );
  }
}

class _Nearby extends StatelessWidget {
  const _Nearby({required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final peers = context.select<NearbyViewModel, List<DiscoveredPeer>>(
      (viewModel) => viewModel.peers,
    );
    if (peers.isEmpty) {
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
      ],
    );
  }
}
