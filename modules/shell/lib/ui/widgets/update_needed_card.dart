import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says which device needs a newer Ferret before the two can talk again,
/// instead of a device that just never connects.
class UpdateNeededCard extends StatelessWidget {
  const UpdateNeededCard({
    super.key,
    required this.mismatch,
    required this.deviceName,
    required this.here,
    this.onGetUpdate,
  });

  final VersionMismatch mismatch;
  final String deviceName;

  /// What to call the device Ferret runs on, such as "this Mac".
  final String here;

  /// Opens where this device gets Ferret, when it is the one to update and
  /// there is such a place.
  final VoidCallback? onGetUpdate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final (title, body) = switch (mismatch.update) {
      .otherDevice => (
        l10n.updateThereTitle(deviceName),
        l10n.updateThereBody(
          deviceName,
          switch (mismatch.remoteAppVersion) {
            '' => '?',
            final version => version,
          },
          here,
        ),
      ),
      .thisDevice => (
        l10n.updateHereTitle(here),
        l10n.updateHereBody(deviceName, here),
      ),
    };
    final getsUpdate = switch (mismatch.update) {
      .thisDevice => onGetUpdate,
      .otherDevice => null,
    };

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.circleArrowUp,
                size: Spacing.d20,
                color: palette.warning,
              ),
              Spacing.h8,
              Expanded(
                child: Text(
                  title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
              ),
            ],
          ),
          Spacing.v4,
          Text(
            body,
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
          if (getsUpdate != null) ...[
            Spacing.v12,
            Align(
              alignment: .centerLeft,
              child: Button(
                variant: .primary,
                mainAxisSize: .min,
                label: l10n.updateGet,
                onPressed: getsUpdate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
