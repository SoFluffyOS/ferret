import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What stands between this computer and the iPhone, in plain words, with
/// the button that fixes it.
class LinkProblemCard extends StatelessWidget {
  const LinkProblemCard({
    super.key,
    required this.link,
    required this.onOpenBluetooth,
    required this.onSetUp,
    required this.onRetry,
  });

  final LinkState link;
  final VoidCallback onOpenBluetooth;
  final VoidCallback onSetUp;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.iphoneL10n;
    final device = switch (link.deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => link.deviceName,
    };
    final openBluetooth = Button(
      mainAxisSize: .min,
      variant: .primary,
      label: l10n.openBluetoothSettings,
      onPressed: onOpenBluetooth,
    );
    final tryAgain = Button(
      mainAxisSize: .min,
      variant: .ghost,
      label: l10n.tryAgain,
      onPressed: onRetry,
    );
    final setUp = Button(
      mainAxisSize: .min,
      variant: .primary,
      label: l10n.setUp,
      onPressed: onSetUp,
    );
    final (icon, title, body, actions) = switch (link.phase) {
      .bluetoothOff => (
        LucideIcons.bluetoothOff,
        l10n.problemBluetoothOffTitle,
        l10n.problemBluetoothOffBody,
        [openBluetooth, tryAgain],
      ),
      .unauthorized => (
        LucideIcons.bluetoothOff,
        l10n.problemUnauthorizedTitle,
        l10n.problemUnauthorizedBody,
        [tryAgain],
      ),
      .notShared => (
        LucideIcons.smartphone,
        l10n.problemNotSharedTitle(device),
        l10n.problemNotSharedBody(device),
        [setUp, tryAgain],
      ),
      _ => (
        LucideIcons.smartphone,
        l10n.problemNoDeviceTitle,
        l10n.problemNoDeviceBody,
        [setUp],
      ),
    };

    return FeatureCard(
      icon: icon,
      iconTone: .warning,
      title: title,
      subtitle: body,
      actions: actions,
    );
  }
}
