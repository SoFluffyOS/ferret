import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notices as Windows toasts. A transfer's progress moves the bar of the
/// toast already there, through data bindings, instead of popping a new
/// toast every second; a silent notice makes no sound; a ringing call
/// shows as a call, which stays on screen.
class WindowsToasts {
  static const titleKey = 'ferretTitle';
  static const bodyKey = 'ferretBody';
  static const statusKey = 'ferretStatus';
  static const barId = 'ferret';

  /// Toasts with a progress bar that later updates can move.
  final Set<int> _withProgress = {};

  /// The bindings that bring the progress toast [id] up to [notice], or
  /// null when [notice] needs a toast of its own: it has no progress, or
  /// no progress toast is showing for it.
  Map<String, String>? update(int id, LocalNotice notice) {
    final progress = notice.progress;
    if (progress == null) {
      _withProgress.remove(id);
      return null;
    }

    if (!_withProgress.contains(id)) {
      return null;
    }

    return {..._texts(notice), '$barId-progressValue': '$progress'};
  }

  /// A new toast for [notice]. Its title and body are bindings when it has
  /// progress, so [update] can change them too.
  ({String title, String body, WindowsNotificationDetails details}) toast(
    int id,
    LocalNotice notice,
    List<NoticeAction> actions,
  ) {
    final progress = notice.progress;
    final silent = notice.silent || progress != null;
    final details = WindowsNotificationDetails(
      actions: [
        for (final action in actions)
          WindowsAction(
            content: action.label,
            arguments: action.id,
            inputId: switch (action.isReply) {
              true => action.id,
              false => null,
            },
          ),
      ],
      inputs: [
        for (final action in actions)
          if (action.isReply)
            WindowsTextInput(id: action.id, placeHolderContent: action.label),
      ],
      audio: switch (silent) {
        true => WindowsNotificationAudio.silent(),
        false => null,
      },
      scenario: switch (notice.ringing) {
        true => WindowsNotificationScenario.incomingCall,
        false => null,
      },
      progressBars: [
        if (progress != null)
          WindowsProgressBar(
            id: barId,
            status: '{$statusKey}',
            value: progress,
          ),
      ],
      bindings: switch (progress) {
        null => const {},
        _ => _texts(notice),
      },
    );
    if (progress == null) {
      _withProgress.remove(id);
      return (title: notice.title, body: notice.body, details: details);
    }

    _withProgress.add(id);
    return (title: '{$titleKey}', body: '{$bodyKey}', details: details);
  }

  /// [id] is gone, so the next notice for it gets a toast of its own.
  void forget(int id) => _withProgress.remove(id);

  static Map<String, String> _texts(LocalNotice notice) => {
    titleKey: notice.title,
    bodyKey: notice.body,
    statusKey: '',
  };
}
