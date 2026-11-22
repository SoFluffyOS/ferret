import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// After Ferret was copied here from another computer and started over:
/// which devices to pair again, until they are back or the note is put
/// away.
class MovedHereFrame extends StatelessWidget {
  const MovedHereFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<MovedDevice>>(
      (host) => host.toPairAgain,
    );
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    final host = context.read<EngineHost>();

    return MovedHereCard(
      here: context.shellL10n.here(host.engine.device),
      names: [for (final device in devices) device.name],
      onDismiss: () => unawaited(host.dismissMoved()),
    );
  }
}
