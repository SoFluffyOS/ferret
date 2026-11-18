import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Asks which connected device should get the files.
class DevicePickerDialog extends StatelessWidget {
  const DevicePickerDialog({super.key, required this.targets});

  final List<DropTarget> targets;

  static Future<DropTarget?> show(
    BuildContext context,
    List<DropTarget> targets,
  ) => showGeneralDialog<DropTarget>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.dropL10n.actionCancel,
    barrierColor: FluffyColors.barrier,
    pageBuilder: (_, _, _) => DevicePickerDialog(targets: targets),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.dropL10n;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d320),
        child: SurfaceCard(
          padding: EdgeInsets.all(Spacing.d20),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.pickerTitle,
                textAlign: .center,
                style: typography.title3.copyWith(color: palette.text),
              ),
              Spacing.v16,
              for (final target in targets)
                Padding(
                  padding: EdgeInsets.only(bottom: Spacing.d8),
                  child: Button(
                    variant: .secondary,
                    label: target.name,
                    icon: Icon(
                      deviceIconFor(target.formFactor, target.platform),
                      size: Spacing.d16,
                    ),
                    mainAxisAlignment: .start,
                    onPressed: () => Navigator.of(context).pop(target),
                  ),
                ),
              Spacing.v8,
              Button(
                variant: .ghost,
                label: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
