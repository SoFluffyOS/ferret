import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// macOS only: keep Ferret in the Dock all the time, and not only while its
/// desktop window is open.
class DockSettings extends StatelessWidget {
  const DockSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final canOpenWindow = context.select<AppViews?, bool>(
      (views) => views?.canOpenWindow ?? false,
    );
    final alwaysInDock = context.select<AppViews?, bool>(
      (views) => views?.alwaysInDock ?? false,
    );
    if (!canOpenWindow) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsDock),
        SurfaceCard(
          child: SwitchRow(
            title: l10n.settingsAlwaysInDock,
            subtitle: l10n.settingsAlwaysInDockBody,
            value: alwaysInDock,
            onChanged: (always) =>
                unawaited(context.read<AppViews>().setAlwaysInDock(always)),
          ),
        ),
      ],
    );
  }
}
