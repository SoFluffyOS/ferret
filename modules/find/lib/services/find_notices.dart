import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:find/feature/find_feature.dart';
import 'package:find/l10n/l10n.dart';

/// The "Ferret is ringing · Found it" notice on platforms that don't show
/// their own (all but Android). Any tap on it means the device was found.
class FindNotices {
  FindNotices({
    required this.feature,
    required this.notifier,
    required this.l10n,
  });

  static const noticeId = 'find.ringing';
  static const category = 'find.ringing';
  static const foundAction = 'found';

  final FindFeature feature;
  final LocalNotifier notifier;
  final FindLocalizations l10n;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// The start of the ring the notice is showing for, if any.
  DateTime? _shownFor;

  static List<NoticeCategory> categories(FindLocalizations l10n) => [
    NoticeCategory(
      id: category,
      actions: [NoticeAction(id: foundAction, label: l10n.foundIt)],
    ),
  ];

  void start() {
    _subscriptions
      ..add(feature.changes.listen((_) => unawaited(_sync())))
      ..add(
        notifier.responses
            .where((response) => response.noticeId == noticeId)
            .listen((_) => unawaited(feature.foundIt())),
      );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  Future<void> _sync() async {
    final ring = feature.localRing;
    if (feature.abilities.showsOwnAlert) {
      return;
    }

    if (!ring.isRinging) {
      if (_shownFor == null) {
        return;
      }

      _shownFor = null;
      await notifier.cancel(noticeId);
      return;
    }

    if (_shownFor == ring.startedAt) {
      return;
    }

    _shownFor = ring.startedAt;
    await notifier.show(
      LocalNotice(
        id: noticeId,
        channel: .find,
        title: l10n.ringingTitle,
        body: l10n.ringingBody(ring.requesterName),
        category: category,
        silent: true,
      ),
    );
  }
}
