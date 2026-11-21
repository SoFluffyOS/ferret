import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What few people need: this device's ID and address, whether pairings
/// are shared, the low battery notice, a network check, and quitting
/// (closing the screen on Android).
class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final l10n = context.shellL10n;
    // Android's service keeps Ferret running after the screen closes.
    final closesOnly = defaultTargetPlatform == .android;

    return FerretPage(
      title: l10n.settingsAdvanced,
      backLabel: l10n.back,
      children: [
        ConnectByHandCard(engine: engine),
        Spacing.v24,
        PairingSettings(engine: engine),
        const GlobalShortcutSettings(),
        const GlobalShortcutSettings.clips(),
        Spacing.v24,
        const LanguageSettings(),
        Spacing.v24,
        const BatterySettings(),
        Spacing.v24,
        GroupedCard(
          children: [
            NavRow(
              title: l10n.settingsCheckNetwork,
              onTap: () => Navigator.of(context).push(
                ferretRoute<void>(
                  const DoctorPage(),
                ),
              ),
            ),
          ],
        ),
        // iOS never lets an app quit itself.
        if (defaultTargetPlatform != .iOS) ...[
          Spacing.v24,
          GhostButton(
            label: closesOnly ? l10n.settingsClose : l10n.settingsQuit,
            tooltip: closesOnly ? l10n.settingsCloseTip : null,
            onPressed: SystemNavigator.pop,
          ),
        ],
      ],
    );
  }
}
