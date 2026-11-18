import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This device as the others see it: its name, with Rename.
class ThisDeviceCard extends StatefulWidget {
  const ThisDeviceCard({super.key, required this.engine});

  final FerretEngine engine;

  /// Asks for a new name for this device and tells the other devices.
  static Future<void> rename(BuildContext context, FerretEngine engine) async {
    final l10n = context.shellL10n;
    final name = await InputTextDialog.show(
      context,
      title: l10n.settingsRenameTitle,
      labelText: l10n.onboardNameLabel,
      initialValue: engine.device.name,
      cancelText: l10n.cancel,
      confirmText: l10n.settingsRename,
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }

    await engine.rename(name);
  }

  @override
  State<ThisDeviceCard> createState() => _ThisDeviceCardState();
}

class _ThisDeviceCardState extends State<ThisDeviceCard> {
  @override
  Widget build(BuildContext context) {
    final device = widget.engine.device;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return SurfaceCard(
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
          Spacing.h12,
          Button(
            variant: .ghost,
            label: l10n.settingsRename,
            onPressed: _rename,
          ),
        ],
      ),
    );
  }

  Future<void> _rename() async {
    await ThisDeviceCard.rename(context, widget.engine);
    if (mounted) {
      setState(() {});
    }
  }
}
