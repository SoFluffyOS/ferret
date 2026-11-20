import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';

/// This Mac's lines in Activity for its keyboard and mouse: pinned while
/// they are on another computer or waiting for its owner, with a way back,
/// and the reason when a switch didn't work.
List<ActivityItem> screenSwitchActivity(
  RemoteInputLocalizations l10n,
  ScreenSwitchViewModel viewModel,
) {
  final state = viewModel.state;
  final name = state.deviceName;
  final problem = state.problem;

  switch (state.phase) {
    case .away:
      return [
        ActivityItem(
          id: 'remote_input.screen',
          icon: LucideIcons.keyboard,
          title: l10n.activityScreenAway(name),
          detail: l10n.activityScreenAwayDetail,
          at: state.at,
          deviceId: state.deviceId,
          pinned: true,
          actions: [
            ActivityAction(
              label: l10n.screenBringBack,
              onPressed: () => unawaited(viewModel.home()),
            ),
          ],
        ),
      ];
    case .asking:
      return [
        ActivityItem(
          id: 'remote_input.screen',
          icon: LucideIcons.keyboard,
          title: l10n.activityScreenAsking(name),
          at: state.at,
          deviceId: state.deviceId,
          pinned: true,
          actions: [
            ActivityAction(
              label: l10n.cancel,
              onPressed: () => unawaited(viewModel.home()),
            ),
          ],
        ),
      ];
    case .home when problem != null:
      return [
        ActivityItem(
          id: 'remote_input.screen.${state.at?.millisecondsSinceEpoch}',
          icon: LucideIcons.keyboard,
          title: l10n.screenProblemTitle(state),
          detail: l10n.screenProblemBody(state),
          at: state.at,
          deviceId: state.deviceId,
          tone: .warning,
          actions: [
            if (problem == .needsAccess)
              ActivityAction(
                label: l10n.allowAccess,
                onPressed: () => unawaited(viewModel.requestAccess()),
              ),
          ],
          onDismiss: viewModel.dismissProblem,
        ),
      ];
    case .home:
      return const [];
  }
}
