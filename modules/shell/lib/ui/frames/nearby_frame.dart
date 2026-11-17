import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:transport/transport.dart';

/// Unpaired Ferret devices on this network.
class NearbyFrame extends StatelessWidget {
  const NearbyFrame({super.key, required this.onPair});

  final void Function(DiscoveredPeer peer) onPair;

  @override
  Widget build(BuildContext context) {
    final nearby = context.select<EngineHost, List<DiscoveredPeer>>(
      (host) => host.nearby,
    );
    if (nearby.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(context.shellL10n.homeNearby),
        for (final peer in nearby)
          NearbyTile(peer: peer, onTap: () => onPair(peer)),
      ],
    );
  }
}
