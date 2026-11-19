import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:scripting/l10n/l10n.dart';
import 'package:scripting/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Scripts in a computer's Settings: what watch and hooks are, the hooks
/// folder, and which hooks would run.
class ScriptingSettingsFrame extends StatelessWidget {
  const ScriptingSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final installed = context.select<ScriptingViewModel, List<String>>(
      (viewModel) => viewModel.installed,
    );
    final viewModel = context.read<ScriptingViewModel>();
    final l10n = context.scriptingL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final muted = typography.base2.copyWith(color: palette.mutedText);
    final hooksLine = switch (installed) {
      [] => l10n.hooksNone,
      final events => l10n.hooksActive(events.join(', ')),
    };

    return GroupedCard(
      children: [
        GroupedCell(
          child: Text(
            l10n.settingsIntro(ThisComputer.here),
            style: typography.base2,
          ),
        ),
        GroupedCell(
          child: Column(
            crossAxisAlignment: .start,
            spacing: Spacing.d4,
            children: [
              Text(l10n.hooksFolder, style: typography.base2),
              Text(viewModel.folder, style: muted),
              Text(hooksLine, style: muted),
              Text(l10n.hooksPrivacy, style: muted),
            ],
          ),
        ),
        GroupedCell(
          child: Row(
            spacing: Spacing.d8,
            children: [
              Button(
                variant: .ghost,
                mainAxisSize: .min,
                label: l10n.copyPath,
                onPressed: () => unawaited(
                  Clipboard.setData(ClipboardData(text: viewModel.folder)),
                ),
              ),
              Button(
                variant: .ghost,
                mainAxisSize: .min,
                label: l10n.checkAgain,
                onPressed: () => unawaited(viewModel.refresh()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
