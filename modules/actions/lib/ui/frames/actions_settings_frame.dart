import 'dart:async';

import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/frames/custom_action_editor.dart';
import 'package:actions/ui/frames/leave_lock_settings_frame.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This computer's actions in Settings: on or off, the owner's own
/// actions with what each runs, locking when a phone leaves, and the
/// history of what devices ran.
/// Which device may run what without asking is on that device's page.
class ActionsSettingsFrame extends StatefulWidget {
  const ActionsSettingsFrame({super.key});

  /// How many past runs the history shows.
  static const historyShown = 5;

  @override
  State<ActionsSettingsFrame> createState() => _ActionsSettingsFrameState();
}

class _ActionsSettingsFrameState extends State<ActionsSettingsFrame> {
  /// The action being edited, [_newAction] for one being added, or null.
  String? _editing;

  static const _newAction = '';

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<ActionsViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final custom = context.select<ActionsViewModel, List<CustomAction>>(
      (viewModel) => viewModel.custom,
    );
    final viewModel = context.read<ActionsViewModel>();
    final l10n = context.actionsL10n;
    final note = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.settingsEnabled(ComputerKind.here.name),
              body: l10n.settingsEnabledBody,
              value: enabled,
              onChanged: (value) => unawaited(viewModel.setEnabled(value)),
            ),
            GroupedCell(child: Text(l10n.settingsPerDevice, style: note)),
          ],
        ),
        SectionTitle(l10n.yourActionsTitle),
        GroupedCard(
          children: [
            if (custom.isEmpty && _editing == null)
              GroupedCell(child: Text(l10n.yourActionsEmpty, style: note)),
            for (final action in custom)
              switch (_editing == action.id) {
                true => _editor(action),
                false => GroupedRow(
                  key: ValueKey(action.id),
                  title: action.name,
                  subtitle: action.commandLine,
                  titleMaxLines: 1,
                  trailing: Button(
                    mainAxisSize: .min,
                    variant: .ghost,
                    label: l10n.editAction,
                    onPressed: () => setState(() => _editing = action.id),
                  ),
                ),
              },
            if (_editing == _newAction) _editor(null),
            if (_editing == null)
              GroupedCell(
                child: Row(
                  children: [
                    Button(
                      mainAxisSize: .min,
                      variant: .ghost,
                      label: l10n.addAction,
                      icon: Icon(LucideIcons.plus, size: Spacing.d16),
                      onPressed: () => setState(() => _editing = _newAction),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const LeaveLockSettingsFrame(),
        const _History(),
      ],
    );
  }

  Widget _editor(CustomAction? action) => CustomActionEditor(
    key: ValueKey('edit.${action?.id}'),
    action: action,
    onSave: (name, commandLine) => _close(
      context.read<ActionsViewModel>().saveCustom(
        id: action?.id,
        name: name,
        commandLine: commandLine,
      ),
    ),
    onRemove: switch (action) {
      final action? => () => _close(
        context.read<ActionsViewModel>().removeCustom(action.id),
      ),
      null => null,
    },
    onCancel: () => setState(() => _editing = null),
  );

  void _close(Future<void> change) {
    unawaited(change);
    setState(() => _editing = null);
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final history = context.select<ActionsViewModel, List<ActionRecord>>(
      (viewModel) => viewModel.history,
    );
    final viewModel = context.read<ActionsViewModel>();
    final l10n = context.actionsL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.historyTitle),
        GroupedCard(
          children: [
            if (history.isEmpty)
              GroupedCell(
                child: Text(
                  l10n.historyEmpty,
                  style: context.fluffyTheme.typography.caption1.copyWith(
                    color: context.palette.mutedText,
                  ),
                ),
              ),
            for (final record in history.take(
              ActionsSettingsFrame.historyShown,
            ))
              GroupedRow(
                title: l10n.recordTitle(
                  l10n.actionLabel(record.kind, record.title),
                  record.deviceName,
                ),
                subtitle: l10n.recordDetailOf(
                  record,
                  commandSeconds: viewModel.commandSeconds,
                ),
                value: ClockText.timeOfDay(
                  Localizations.localeOf(context).toLanguageTag(),
                  record.at,
                ),
              ),
            if (history.isNotEmpty)
              GroupedCell(
                child: Row(
                  children: [
                    Button(
                      mainAxisSize: .min,
                      variant: .ghost,
                      label: l10n.clearHistory,
                      onPressed: () => unawaited(viewModel.clearHistory()),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
