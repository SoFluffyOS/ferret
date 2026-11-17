import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// The paired devices, connected ones first.
class DevicesFrame extends StatelessWidget {
  const DevicesFrame({super.key, required this.onOpen, required this.onPair});

  final void Function(DeviceStatus status) onOpen;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    if (devices.isEmpty) {
      return EmptyDevices(onPair: onPair);
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(context.shellL10n.homeYourDevices),
        for (final status in devices)
          DeviceTile(status: status, onTap: () => onOpen(status)),
      ],
    );
  }
}
