import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Picks the device to continue on; pops with its id.
class DevicePickerPage extends StatelessWidget {
  const DevicePickerPage({super.key, required this.devices});

  final List<HandoffPeer> devices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.handoffL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return FerretPage(
      title: l10n.pickDeviceTitle,
      backLabel: l10n.back,
      children: [
        if (devices.isEmpty)
          SurfaceCard(
            child: Text(
              l10n.pickDeviceEmpty,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
          ),
        for (final device in devices)
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d8),
            child: SurfaceCard(
              onTap: () => Navigator.of(context).pop(device.id),
              child: Row(
                children: [
                  Icon(
                    deviceIconFor(device.formFactor, device.platform),
                    size: Spacing.d24,
                    color: palette.text,
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Text(
                      device.name,
                      style: typography.base1.copyWith(color: palette.text),
                      overflow: .ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
