import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Continue's settings: passive suggestions, automatic opening, and the
/// platform extras (browser page on macOS, assistant on Android). The
/// browser extension has its own part, [BrowserSettingsFrame].
class HandoffSettingsFrame extends StatelessWidget {
  const HandoffSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.handoffL10n;
    final viewModel = context.read<HandoffViewModel>();
    final passive = context.select<HandoffViewModel, bool>(
      (viewModel) => viewModel.passiveEnabled,
    );
    final openAutomatically = context.select<HandoffViewModel, bool>(
      (viewModel) => viewModel.opensAutomatically,
    );
    final browserTab = context.select<HandoffViewModel, bool>(
      (viewModel) => viewModel.browserTabEnabled,
    );
    final hasHistory = context.select<HandoffViewModel, bool>(
      (viewModel) => viewModel.hasHistory,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.settingsPassive,
              body: l10n.settingsPassiveBody,
              value: passive,
              onChanged: viewModel.setPassiveEnabled,
            ),
            SettingSwitchRow(
              title: l10n.settingsOpenAutomatically,
              body: l10n.settingsOpenAutomaticallyBody,
              value: openAutomatically,
              onChanged: viewModel.setOpensAutomatically,
            ),
            if (viewModel.supportsBrowserTab)
              SettingSwitchRow(
                title: l10n.settingsBrowserTab,
                body: l10n.settingsBrowserTabBody,
                value: browserTab,
                onChanged: viewModel.setBrowserTabEnabled,
              ),
            GroupedRow(
              title: l10n.settingsHistory,
              subtitle: l10n.settingsHistoryBody,
              trailing: Button(
                variant: .ghost,
                label: l10n.settingsHistoryClear,
                mainAxisSize: .min,
                onPressed: switch (hasHistory) {
                  true => viewModel.clearHistory,
                  false => null,
                },
              ),
            ),
          ],
        ),
        if (viewModel.supportsAssistant) ...[
          Spacing.v24,
          const _AssistantSetup(),
        ],
      ],
    );
  }
}

class _AssistantSetup extends StatelessWidget {
  const _AssistantSetup();

  @override
  Widget build(BuildContext context) {
    final l10n = context.handoffL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final viewModel = context.read<HandoffViewModel>();
    final enabled = context.select<HandoffViewModel, bool?>(
      (viewModel) => viewModel.assistantEnabled,
    );
    final status = switch (enabled) {
      true => l10n.settingsAssistantOn,
      false => l10n.settingsAssistantOff,
      null => '',
    };
    final statusColor = switch (enabled) {
      true => palette.success,
      _ => palette.mutedText,
    };

    return GroupedCard(
      children: [
        GroupedRow(
          title: l10n.settingsAssistantTitle,
          subtitle: l10n.settingsAssistantBody,
          trailing: Button(
            variant: .ghost,
            label: l10n.settingsAssistantOpen,
            mainAxisSize: .min,
            onPressed: viewModel.openAssistantSettings,
          ),
        ),
        GroupedCell(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              if (status.isNotEmpty) ...[
                Text(
                  status,
                  style: typography.caption1.copyWith(color: statusColor),
                ),
                Spacing.v8,
              ],
              Text(
                l10n.settingsShareHint,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
