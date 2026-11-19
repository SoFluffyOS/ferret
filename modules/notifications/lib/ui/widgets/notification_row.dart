import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/ui/widgets/app_icon.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A mirrored notification in one compact row, with a dismiss button.
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final MirroredNotification notification;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final time = ClockText.timeOfDay(
      Localizations.localeOf(context).toLanguageTag(),
      notification.postedAt,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          AppIcon(png: notification.appIcon, size: Spacing.d20),
          Spacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  '${notification.heading} · $time',
                  style: typography.caption1.copyWith(color: palette.text),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                if (notification.text.isNotEmpty)
                  Text(
                    notification.text,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
              ],
            ),
          ),
          Tappable(
            tooltip: dismissLabel,
            onTap: onDismiss,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d4),
              child: Icon(
                LucideIcons.x,
                size: Spacing.d14,
                color: palette.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
