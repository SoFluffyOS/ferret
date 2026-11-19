import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Asks before removing the devices nobody has seen for a month, naming
/// each one.
class StaleDevicesCard extends StatelessWidget {
  const StaleDevicesCard({
    super.key,
    required this.names,
    required this.here,
    required this.onRemove,
    required this.onCancel,
  });

  final List<String> names;

  /// What to call the device Ferret runs on, such as "this Mac".
  final String here;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: SurfaceCard(
        padding: EdgeInsets.all(Spacing.d16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              l10n.devicesStaleConfirm(
                ListText.join(names, localeName: l10n.localeName),
                here,
              ),
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.v4,
            Text(
              l10n.devicesStaleConfirmBody,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
            Spacing.v12,
            Row(
              children: [
                Button(
                  mainAxisSize: .min,
                  variant: .ghost,
                  color: palette.danger,
                  label: l10n.devicesStaleRemove,
                  onPressed: onRemove,
                ),
                Spacing.h8,
                Button(
                  mainAxisSize: .min,
                  variant: .ghost,
                  label: l10n.cancel,
                  onPressed: onCancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
