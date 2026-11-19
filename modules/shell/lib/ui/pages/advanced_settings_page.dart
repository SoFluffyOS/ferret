import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/connect_by_hand_card.dart';
import 'package:shell/ui/frames/global_shortcut_settings.dart';
import 'package:shell/ui/frames/pairing_settings.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/widgets/nav_row.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What few people need: this device's ID and address, whether pairings
/// are shared, a network check, and quitting.
class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final l10n = context.shellL10n;

    return FerretPage(
      title: l10n.settingsAdvanced,
      backLabel: l10n.back,
      children: [
        ConnectByHandCard(engine: engine),
        Spacing.v24,
        PairingSettings(engine: engine),
        const GlobalShortcutSettings(),
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
        Spacing.v24,
        Button(
          variant: .ghost,
          label: l10n.settingsQuit,
          onPressed: SystemNavigator.pop,
        ),
      ],
    );
  }
}
