import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One paired device: whether it's connected, what works with it, what to do
/// about it, and forgetting it.
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
        DeviceTile(status: status),
        if (!status.isConnected)
          Button(
            variant: .primary,
            label: l10n.deviceWhyLong,
            onPressed: () => Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => DoctorPage(deviceId: deviceId),
              ),
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
        if (status.isConnected) ...[
          SectionTitle(l10n.deviceWhatWorks(device.name)),
          FeatureChangesListener(
            features: scope.features,
            builder: (context) => SurfaceCard(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  for (final feature in scope.features)
                    if (feature.healthFor(scope.featureContext, status)
                        case final health?)
                      _HealthRow(
                        icon: feature.icon,
                        title: feature.title(context),
                        health: health,
                      ),
                ],
              ),
            ),
          ),
        ],
        SectionTitle(l10n.deviceDetails),
        Text(
          '${l10n.deviceTitleId} ${DeviceIdentity.format(device.id)}',
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
        Spacing.v24,
        Tappable(
          onTap: () => _forget(context, status),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.d8),
            child: Text(
              l10n.deviceForget,
              style: typography.base1.copyWith(color: palette.danger),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _forget(BuildContext context, DeviceStatus status) async {
    final l10n = context.shellL10n;
    final engine = ShellScope.read(context).featureContext.engine;
    final navigator = Navigator.of(context);

    final action = await ConfirmDialog.show(
      context,
      title: l10n.deviceForgetConfirmTitle(status.device.name),
      message: l10n.deviceForgetConfirmBody,
      negativeText: l10n.cancel,
      positiveText: l10n.deviceForget,
    );
    if (action != ConfirmAction.positive) {
      return;
    }

    await engine.unpair(status.device.id);
    navigator.pop();
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.icon,
    required this.title,
    required this.health,
  });

  final IconData icon;
  final String title;
  final FeatureHealth health;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final color = switch (health.state) {
      .ok => palette.success,
      .needsAttention => palette.warning,
      .failing => palette.danger,
      .off => palette.mutedText,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Icon(icon, size: Spacing.d18, color: color),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: typography.base2.copyWith(color: palette.text),
                ),
                if (health.reason.isNotEmpty)
                  Text(
                    health.reason,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
