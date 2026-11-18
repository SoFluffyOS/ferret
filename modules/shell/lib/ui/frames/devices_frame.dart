import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// The paired devices, connected ones first, each with its features' health.
class DevicesFrame extends StatelessWidget {
  const DevicesFrame({
    super.key,
    required this.onOpen,
    required this.onPair,
    required this.onWhy,
  });

  final void Function(DeviceStatus status) onOpen;
  final VoidCallback onPair;
  final void Function(DeviceStatus status) onWhy;

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    final scope = ShellScope.of(context);
    if (devices.isEmpty) {
      return EmptyDevices(onPair: onPair);
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(context.shellL10n.homeYourDevices),
        for (final status in devices)
          FeatureChangesListener(
            features: scope.features,
            builder: (context) => DeviceTile(
              status: status,
              chips: [
                for (final feature in scope.features)
                  if (feature.healthFor(scope.featureContext, status)
                      case final health?)
                    FeatureChip(
                      icon: feature.icon,
                      label: feature.title(context),
                      health: health,
                    ),
              ],
              onTap: () => onOpen(status),
              onWhy: () => onWhy(status),
            ),
          ),
      ],
    );
  }
}
