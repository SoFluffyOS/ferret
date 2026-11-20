import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/services/screen_switch.dart';
import 'package:remote_input/ui/widgets/remote_input_labels.dart';

/// The switch keys work from any app, with Ferret out of sight, so a
/// switch that didn't work says why in a system notice: a password field,
/// missing access (with Open Settings), a computer that said no or went
/// away.
class ScreenNotices {
  ScreenNotices({
    required this.screenSwitch,
    required this.notifier,
    required this.l10n,
  });

  static const problemNotice = 'remote_input.screen';
  static const accessNotice = 'remote_input.screen_access';
  static const openSettingsAction = 'open_settings';

  final ScreenSwitch screenSwitch;
  final LocalNotifier notifier;
  final RemoteInputLocalizations l10n;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  DateTime? _shownFor;

  static List<NoticeCategory> categories(RemoteInputLocalizations l10n) => [
    NoticeCategory(
      id: accessNotice,
      actions: [
        NoticeAction(
          id: openSettingsAction,
          label: l10n.openSettings,
          opensApp: true,
        ),
      ],
    ),
  ];

  void start() {
    _subscriptions
      ..add(screenSwitch.changes.listen((_) => unawaited(_sync())))
      ..add(
        notifier.responses
            .where((response) => response.noticeId == accessNotice)
            .listen((_) => unawaited(screenSwitch.requestAccess())),
      );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  Future<void> _sync() async {
    final state = screenSwitch.state;
    final problem = state.problem;
    if (problem == null || state.at == null || state.at == _shownFor) {
      return;
    }

    _shownFor = state.at;
    final id = switch (problem) {
      .needsAccess => accessNotice,
      _ => problemNotice,
    };
    await notifier.show(
      LocalNotice(
        id: id,
        channel: .problems,
        title: l10n.screenProblemTitle(state),
        body: l10n.screenProblemBody(state),
        category: switch (problem) {
          .needsAccess => accessNotice,
          _ => null,
        },
      ),
    );
  }
}
