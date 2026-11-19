import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/ui/widgets/widgets.dart';

/// A device's Screen section before anything is shown: one sentence on
/// what it does, and the one button that starts it.
class ScreenLauncherFrame extends StatelessWidget {
  const ScreenLauncherFrame({
    super.key,
    required this.deviceName,
    required this.onShow,
  });

  final String deviceName;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.mirroringL10n;

    return MirrorMessage(
      icon: LucideIcons.smartphone,
      title: l10n.launcherTitle(deviceName, ThisComputer.here),
      body: l10n.launcherBody(deviceName),
      actions: [
        MessageAction(label: l10n.showScreen, primary: true, onPressed: onShow),
      ],
    );
  }
}
