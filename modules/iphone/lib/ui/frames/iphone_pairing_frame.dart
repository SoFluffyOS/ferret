import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/ui/widgets/widgets.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The pairing steps for this computer, and the paired devices to pick from.
class IphonePairingFrame extends StatelessWidget {
  const IphonePairingFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.select<IphoneSettingsViewModel, IphoneHostKind>(
      (viewModel) => viewModel.host,
    );
    final devices = context.select<IphoneSettingsViewModel, List<BondedDevice>>(
      (viewModel) => viewModel.devices,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final pairStep = switch (host) {
      .windows => l10n.setupStepPairWindows,
      .macos => l10n.setupStepPairMac,
      .linux => l10n.setupStepPairLinux,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SetupSteps(
          title: l10n.setupTitle,
          steps: [
            l10n.setupStepUnlock,
            pairStep,
            l10n.setupStepAllow(ThisComputer.here),
            l10n.setupStepChoose,
          ],
        ),
        Spacing.v8,
        Wrap(
          spacing: Spacing.d8,
          runSpacing: Spacing.d8,
          children: [
            Button(
              mainAxisSize: .min,
              variant: .primary,
              label: l10n.openBluetoothSettings,
              onPressed: () => unawaited(viewModel.openBluetoothSettings()),
            ),
            GhostButton(
              mainAxisSize: .min,
              label: l10n.devicesRefresh,
              onPressed: () => unawaited(viewModel.loadDevices()),
            ),
          ],
        ),
        Spacing.v12,
        Text(
          l10n.devicesTitle,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
        if (devices.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: Spacing.d4),
            child: Text(
              l10n.devicesEmpty,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
          ),
        for (final device in devices)
          DeviceRow(
            key: ValueKey(device.id),
            name: switch (device.name.isEmpty) {
              true => l10n.deviceUnnamed,
              false => device.name,
            },
            detail: switch (device.connected) {
              true => l10n.deviceConnected,
              false => null,
            },
            actionLabel: l10n.deviceUse,
            onAction: () => unawaited(viewModel.choose(device)),
          ),
      ],
    );
  }
}
