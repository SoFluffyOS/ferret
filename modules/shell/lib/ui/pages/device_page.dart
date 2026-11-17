import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One paired device: what features can do with it, and unpairing.
class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final status = context.select<EngineHost, DeviceStatus?>(
      (host) => host.statusOf(deviceId),
    );
    final scope = ShellScope.of(context);
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    if (status == null) {
      return FerretPage(title: '', backLabel: l10n.back, children: const []);
    }

    final device = status.device;
    final actions = switch (status.isConnected) {
      true => [
        for (final feature in scope.features)
          ...feature.deviceActions(context, scope.featureContext, status),
      ],
      false => const <FeatureAction>[],
    };

    return FerretPage(
      title: device.name,
      backLabel: l10n.back,
      children: [
        SurfaceCard(
          child: Row(
            children: [
              Icon(
                deviceIconFor(device.formFactor, device.platform),
                size: Spacing.d32,
                color: palette.text,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      switch (status.isConnected) {
                        true => l10n.deviceConnected,
                        false => l10n.deviceOffline,
                      },
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                    Spacing.v4,
                    Text(
                      '${l10n.deviceTitleId} ${DeviceIdentity.format(device.id)}',
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty) SectionTitle(l10n.deviceActions),
        for (final action in actions)
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d8),
            child: Button(
              variant: .secondary,
              label: action.label,
              icon: Icon(action.icon, size: Spacing.d16),
              onPressed: action.onPressed,
              mainAxisAlignment: .start,
            ),
          ),
        Spacing.v24,
        Button(
          variant: .ghost,
          label: l10n.deviceUnpair,
          onPressed: () => _unpair(context, status),
        ),
      ],
    );
  }

  Future<void> _unpair(BuildContext context, DeviceStatus status) async {
    final l10n = context.shellL10n;
    final engine = ShellScope.read(context).featureContext.engine;
    final navigator = Navigator.of(context);

    final action = await ConfirmDialog.show(
      context,
      title: l10n.deviceUnpairConfirmTitle(status.device.name),
      message: l10n.deviceUnpairConfirmBody,
      negativeText: l10n.cancel,
      positiveText: l10n.deviceUnpair,
    );
    if (action != ConfirmAction.positive) {
      return;
    }

    await engine.unpair(status.device.id);
    navigator.pop();
  }
}
