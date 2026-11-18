import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The part of Settings about this device itself: its name, and how Ferret
/// runs on it. Next to the list in a window; on a phone these sit on
/// Settings' first page.
class ThisDeviceSettingsPage extends StatelessWidget {
  const ThisDeviceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final l10n = context.shellL10n;

    return FerretPage(
      title: l10n.settingsThisDevice,
      backLabel: l10n.back,
      children: [
        ThisDeviceCard(engine: engine),
        Spacing.v8,
        BackgroundSettings(settings: engine.settings),
        const DockSettings(),
      ],
    );
  }
}
