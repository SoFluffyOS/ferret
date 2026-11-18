import 'dart:async';

import 'package:find/models/models.dart';
import 'package:find/ui/widgets/widgets.dart';
import 'package:find/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Ringing one device, live: asking, ringing with Stop, or how it ended.
class OutgoingRingFrame extends StatelessWidget {
  const OutgoingRingFrame({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final ring = context.select<FindViewModel, OutgoingRing?>(
      (viewModel) => viewModel.outgoingFor(deviceId),
    );
    if (ring == null) {
      return const SizedBox.shrink();
    }

    final viewModel = context.read<FindViewModel>();

    return OutgoingRingCard(
      ring: ring,
      onStop: () => unawaited(viewModel.stop(deviceId)),
      onRingAgain: () => unawaited(viewModel.ring(deviceId)),
      onDismiss: () {
        viewModel.dismiss(deviceId);
        unawaited(Navigator.of(context).maybePop());
      },
    );
  }
}
