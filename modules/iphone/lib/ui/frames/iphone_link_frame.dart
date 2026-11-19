import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/models/models.dart';
import 'package:iphone/ui/frames/iphone_chosen_actions.dart';
import 'package:iphone/ui/frames/iphone_pairing_frame.dart';
import 'package:iphone/ui/frames/iphone_shared_frame.dart';
import 'package:iphone/ui/widgets/widgets.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The link's state in words, with what to do about it.
class IphoneLinkFrame extends StatelessWidget {
  const IphoneLinkFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final link = context.select<IphoneSettingsViewModel, LinkState>(
      (viewModel) => viewModel.link,
    );
    final openFailed = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    void openBluetooth() => unawaited(viewModel.openBluetoothSettings());
    void retry() => unawaited(viewModel.retry());
    final device = switch (link.deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => link.deviceName,
    };
    final content = switch (link.phase) {
      .off => const <Widget>[],
      .unsupported => [NoticeBlock(title: l10n.statusUnsupported)],
      .notConfigured => [NoticeBlock(title: l10n.statusNotConfigured)],
      .bluetoothOff => [
        NoticeBlock(
          title: l10n.problemBluetoothOffTitle,
          body: l10n.problemBluetoothOffBody,
          actionLabel: l10n.openBluetoothSettings,
          onAction: openBluetooth,
        ),
      ],
      .unauthorized => [
        NoticeBlock(
          title: l10n.problemUnauthorizedTitle,
          body: l10n.problemUnauthorizedBody,
          actionLabel: l10n.tryAgain,
          onAction: retry,
        ),
      ],
      .noDevice => const [IphonePairingFrame()],
      .connecting => [
        IphoneStatusText(
          text: l10n.statusConnecting(device),
          color: palette.mutedText,
        ),
        const IphoneChosenActions(),
      ],
      .connected => [
        IphoneStatusText(
          text: l10n.statusConnected(device),
          color: palette.success,
        ),
        const IphoneSharedFrame(),
        const IphoneChosenActions(),
      ],
      .outOfReach => [
        IphoneStatusText(
          text: l10n.statusOutOfReach(device),
          color: palette.warning,
        ),
        const IphoneChosenActions(showRetry: true),
      ],
      .notShared => [
        NoticeBlock(
          title: l10n.problemNotSharedTitle(device),
          body: l10n.problemNotSharedBody(device),
          actionLabel: l10n.openBluetoothSettings,
          onAction: openBluetooth,
        ),
        const IphoneChosenActions(showRetry: true),
      ],
      .failed => [
        IphoneStatusText(
          text: l10n.statusFailed(device),
          color: palette.warning,
        ),
        const IphoneChosenActions(showRetry: true),
      ],
    };

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        ...content,
        if (openFailed) ...[
          if (content.isNotEmpty) Spacing.v8,
          Text(
            l10n.openFailed,
            style: typography.caption1.copyWith(color: palette.danger),
          ),
        ],
      ],
    );
  }
}
