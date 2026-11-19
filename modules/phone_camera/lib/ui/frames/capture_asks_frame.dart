import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:phone_camera/models/models.dart';
import 'package:phone_camera/ui/widgets/widgets.dart';
import 'package:phone_camera/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// On a phone's home: one card per computer that wants a picture.
class CaptureAsksFrame extends StatelessWidget {
  const CaptureAsksFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final asks = context.select<CaptureAsksViewModel, List<CaptureAsk>>(
      (viewModel) => viewModel.asks,
    );
    if (asks.isEmpty) {
      return const SizedBox.shrink();
    }

    final viewModel = context.read<CaptureAsksViewModel>();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, ask) in asks.indexed) ...[
          if (index > 0) Spacing.v8,
          CaptureAskCard(
            key: ValueKey(ask.requestId),
            ask: ask,
            deviceName: viewModel.nameOf(ask.deviceId),
            onTake: () => unawaited(viewModel.take(ask.requestId)),
            onDecline: () => unawaited(viewModel.decline(ask.requestId)),
          ),
        ],
      ],
    );
  }
}
