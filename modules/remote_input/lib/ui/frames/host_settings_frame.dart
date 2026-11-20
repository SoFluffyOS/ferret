import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This computer's remote input settings: on or off, what it needs on this
/// platform with a way forward, and the history of who controlled it. Which
/// device may control it without asking is on that device's page. Access is
/// checked again when the app comes back from system settings.
class HostSettingsFrame extends StatefulWidget {
  const HostSettingsFrame({super.key});

  /// How many past times the history shows.
  static const historyShown = 5;

  @override
  State<HostSettingsFrame> createState() => _HostSettingsFrameState();
}

class _HostSettingsFrameState extends State<HostSettingsFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<HostViewModel>().checkAgain()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<HostViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final status = context.select<HostViewModel, InjectorStatus?>(
      (viewModel) => viewModel.status,
    );
    final viewModel = context.read<HostViewModel>();
    final l10n = context.remoteInputL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.settingsEnabled(ThisComputer.here),
              body: l10n.settingsEnabledBody,
              value: enabled,
              onChanged: (value) => unawaited(viewModel.setEnabled(value)),
            ),
            if (enabled && status != null)
              GroupedCell(child: _Status(status: status)),
            GroupedCell(
              child: Text(
                l10n.settingsPerDevice(ThisComputer.here),
                style: context.fluffyTheme.typography.caption1.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ),
          ],
        ),
        const _History(),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});

  final InjectorStatus status;

  @override
  Widget build(BuildContext context) {
    final lostAccess = context.select<HostViewModel, bool>(
      (viewModel) => viewModel.lostAccess,
    );
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<HostViewModel>();
    if (status.isReady) {
      return Text(
        l10n.statusLine(status),
        style: context.fluffyTheme.typography.caption1.copyWith(
          color: context.palette.success,
        ),
      );
    }

    final (actionLabel, action) = switch (status.state) {
      .needsPermission => (l10n.allowAccess, viewModel.requestAccess),
      _ => (l10n.checkAgain, viewModel.checkAgain),
    };

    return NoticeBlock(
      title: l10n.statusLine(status),
      body: l10n.statusFix(status),
      actionLabel: actionLabel,
      onAction: () => unawaited(action()),
      isProblem: lostAccess,
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final history = context.select<HostViewModel, List<ControlRecord>>(
      (viewModel) => viewModel.history,
    );
    final viewModel = context.read<HostViewModel>();
    final l10n = context.remoteInputL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsHistoryTitle),
        GroupedCard(
          children: [
            if (history.isEmpty)
              GroupedCell(
                child: Text(
                  l10n.settingsHistoryEmpty(ThisComputer.here),
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
              ),
            for (final record in history.take(HostSettingsFrame.historyShown))
              GroupedRow(title: l10n.audit(record)),
            if (history.isNotEmpty)
              GroupedCell(
                child: GhostButton(
                  label: l10n.clearHistory,
                  onPressed: () => unawaited(viewModel.clearHistory()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
