import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// Asks about each newly paired device that looks like it replaces an old
/// one with the same name. With [deviceId], only about that device.
class SuccessorsFrame extends StatelessWidget {
  const SuccessorsFrame({super.key, this.deviceId});

  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final successors = context.select<EngineHost, List<Successor>>(
      (host) => [
        for (final successor in host.successors)
          if (deviceId == null ||
              successor.replacement.id == deviceId ||
              successor.old.id == deviceId)
            successor,
      ],
    );
    if (successors.isEmpty) {
      return const SizedBox.shrink();
    }

    final host = context.read<EngineHost>();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final successor in successors)
          ReplaceDeviceCard(
            key: ValueKey(successor.replacement.id),
            name: successor.replacement.ownName,
            oldName: successor.old.name,
            onReplace: () => unawaited(host.replace(successor)),
            onKeepBoth: () => unawaited(host.keepBoth(successor)),
          ),
      ],
    );
  }
}
