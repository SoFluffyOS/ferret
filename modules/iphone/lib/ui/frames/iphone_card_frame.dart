import 'dart:async';

import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/models/models.dart';
import 'package:iphone/ui/widgets/widgets.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The home card: what the iPhone plays with its controls, or what the link
/// needs from the person. Nothing while all is quiet.
class IphoneCardFrame extends StatelessWidget {
  const IphoneCardFrame({super.key, required this.onSetUp, this.now});

  /// Opens the pairing steps.
  final VoidCallback onSetUp;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final showsPlayer = context.select<IphoneViewModel, bool>(
      (viewModel) => viewModel.showsPlayer,
    );
    final showsProblem = context.select<IphoneViewModel, bool>(
      (viewModel) => viewModel.showsProblem,
    );
    final link = context.select<IphoneViewModel, LinkState>(
      (viewModel) => viewModel.link,
    );
    final viewModel = context.read<IphoneViewModel>();
    if (showsProblem) {
      return LinkProblemCard(
        link: link,
        onOpenBluetooth: () => unawaited(viewModel.openBluetoothSettings()),
        onSetUp: onSetUp,
        onRetry: () => unawaited(viewModel.retry()),
      );
    }

    if (!showsPlayer) {
      return const SizedBox.shrink();
    }

    return _Player(deviceName: link.deviceName, now: now);
  }
}

class _Player extends StatelessWidget {
  const _Player({required this.deviceName, this.now});

  final String deviceName;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final media = context.select<IphoneViewModel, AmsState>(
      (viewModel) => viewModel.media,
    );
    final commandFailed = context.select<IphoneViewModel, bool>(
      (viewModel) => viewModel.commandFailed,
    );
    final viewModel = context.read<IphoneViewModel>();

    return NowPlayingCard(
      media: media,
      deviceName: deviceName,
      commandFailed: commandFailed,
      onCommand: (command) => unawaited(viewModel.send(command)),
      now: now,
    );
  }
}
