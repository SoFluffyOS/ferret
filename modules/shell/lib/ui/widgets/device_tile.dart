import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/widgets/battery_badge.dart';
import 'package:shell/ui/widgets/pin_marker.dart';
import 'package:shell/ui/widgets/row_action_button.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One paired device on Home: its name, the one thing that is true about its
/// connection, and what to do with it right there. Connected, that is up
/// to three actions; offline, a way to fix it. An iPhone that isn't
/// connected says it connects while Ferret is open on it: iOS stops Ferret
/// in the background, and "Last seen" would read like a fault. While a
/// dropped link redials it says "Reconnecting…" and keeps its buttons,
/// greyed out, so the row doesn't jump on a flaky Wi-Fi.
class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.status,
    this.actions = const [],
    this.hasPrimary = false,
    this.attention,
    this.offlineStatus,
    this.onTap,
    this.onFix,
    this.focusNode,
    this.isPinned = false,
  });

  final DeviceStatus status;

  /// What to do with this device, most useful first. While it is offline,
  /// only what still works then, such as "Wake".
  final List<FeatureAction> actions;

  /// Whether the first action is the screen's one primary button.
  final bool hasPrimary;

  /// The name of a feature that is turned on and not working with this
  /// device, such as "Notifications".
  final String? attention;

  /// What a feature is doing with it while offline, such as waking it, in
  /// place of "Last seen".
  final String? offlineStatus;

  /// Opens the device's page.
  final VoidCallback? onTap;

  /// Finds out why it isn't connected.
  final VoidCallback? onFix;

  /// The row's keyboard focus, for moving between rows with the arrows.
  final FocusNode? focusNode;

  /// Pinned to the top: a small pin follows the name.
  final bool isPinned;

  static const _waitingOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final device = status.device;
    final needsAttention = status.isConnected && attention != null;
    final dotColor = switch ((status.isConnected, needsAttention)) {
      (false, _) when status.isReconnecting => palette.warning,
      (false, _) when status.versionMismatch != null => palette.warning,
      (false, _) => palette.mutedText,
      (true, true) => palette.warning,
      (true, false) => palette.success,
    };
    final showsActions = status.isConnected || status.isReconnecting;
    final statusColor = switch (needsAttention ||
        status.versionMismatch != null) {
      true => palette.warning,
      false => palette.mutedText,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        onTap: onTap,
        focusNode: focusNode,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(
                  deviceIconFor(device.formFactor, device.platform),
                  size: Spacing.d24,
                  color: palette.text,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name,
                              style: typography.base1.copyWith(
                                color: palette.text,
                              ),
                              overflow: .ellipsis,
                            ),
                          ),
                          if (isPinned) ...[Spacing.h4, const PinMarker()],
                        ],
                      ),
                      Spacing.vertical(Spacing.d2),
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: .circle,
                            ),
                            child: SizedBox.square(dimension: Spacing.d6),
                          ),
                          Spacing.h6,
                          Flexible(
                            child: Text(
                              _statusLine(l10n),
                              style: typography.caption1.copyWith(
                                color: statusColor,
                              ),
                              overflow: .ellipsis,
                            ),
                          ),
                          if (status.battery case final battery?) ...[
                            Spacing.h6,
                            BatteryBadge(battery: battery),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!showsActions &&
                    status.versionMismatch == null &&
                    onFix != null) ...[
                  Spacing.h8,
                  RowActionButton(label: l10n.deviceFix, onPressed: onFix),
                ],
                if (status.isConnected && onTap != null) ...[
                  Spacing.h8,
                  DirectionalIcon(
                    LucideIcons.chevronRight,
                    size: Spacing.d16,
                    color: palette.mutedText,
                  ),
                ],
              ],
            ),
            if (actions.isNotEmpty) ...[
              Spacing.v12,
              Opacity(
                opacity: switch (status.isReconnecting) {
                  true => _waitingOpacity,
                  false => 1,
                },
                child: Wrap(
                  spacing: Spacing.d8,
                  runSpacing: Spacing.d8,
                  children: [
                    for (final (index, action) in actions.indexed)
                      RowActionButton(
                        label: action.label,
                        isPrimary:
                            hasPrimary && index == 0 && status.isConnected,
                        onPressed: action.onPressed,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLine(ShellLocalizations l10n) {
    if (status.isConnected) {
      return switch ((attention, status.isWeak, status.isAway)) {
        (final feature?, _, _) => l10n.deviceAttention(feature),
        (null, true, _) => l10n.deviceWeak,
        (null, false, true) => l10n.deviceAway,
        (null, false, false) => l10n.deviceConnected,
      };
    }

    if (status.isReconnecting) {
      return l10n.deviceReconnecting;
    }

    if (status.versionMismatch case final mismatch?) {
      return switch (mismatch.update) {
        .otherDevice => l10n.deviceUpdateThere,
        .thisDevice => l10n.deviceUpdateHere,
      };
    }

    if (offlineStatus case final line?) {
      return line;
    }

    if (status.device.platform == .PLATFORM_IOS) {
      return l10n.deviceConnectsWhenOpen;
    }

    return l10n.lastSeen(status.device.lastSeen);
  }
}
