import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:iphone/models/models.dart';

/// Turns ANCS events into notifications worth showing: fetches their text
/// and the app's name, and leaves out everything that was already on the
/// iPhone when this computer connected, so a reconnect never replays old
/// ones.
class NotificationFeed {
  NotificationFeed(this._ancs);

  final AncsClient _ancs;
  final StreamController<FeedEvent> _events = .broadcast(sync: true);
  final Set<int> _shown = {};

  /// Removed while its text was still being fetched.
  final Set<int> _goneEarly = {};
  final Map<int, int> _fetching = {};

  StreamSubscription<AncsEvent>? _subscription;

  Stream<FeedEvent> get events => _events.stream;

  void start() {
    _subscription ??= _ancs.events.listen(
      (event) => unawaited(_onEvent(event)),
    );
  }

  /// Forgets what was shown: after the link drops, the iPhone's handles
  /// mean nothing any more.
  void reset() {
    _shown.clear();
    _goneEarly.clear();
    _fetching.clear();
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_events.close());
  }

  Future<void> _onEvent(AncsEvent event) async {
    final uid = event.uid;
    if (event.kind == .removed) {
      _onRemoved(uid);
      return;
    }

    if (event.isPreExisting) {
      return;
    }

    _fetching[uid] = (_fetching[uid] ?? 0) + 1;
    final IphoneNotification notification;
    try {
      final fetched = await _ancs.fetch(event);
      final appName = await _ancs.appName(fetched.appId);
      notification = _notificationOf(fetched, appName);
    } on GattException catch (error) {
      // Usually the notification went away before it could be read.
      printDebug(
        'Reading an iPhone notification failed: ${error.failure.name}',
      );
      return;
    } finally {
      _doneFetching(uid);
    }

    if (_goneEarly.remove(uid) || _events.isClosed) {
      return;
    }

    _shown.add(uid);
    _events.add(FeedShown(notification));
  }

  void _doneFetching(int uid) {
    final left = (_fetching[uid] ?? 1) - 1;
    if (left > 0) {
      _fetching[uid] = left;
      return;
    }

    _fetching.remove(uid);
  }

  void _onRemoved(int uid) {
    if (_fetching.containsKey(uid)) {
      _goneEarly.add(uid);
    }

    if (_shown.remove(uid) && !_events.isClosed) {
      _events.add(FeedRemoved(uid));
    }
  }

  IphoneNotification _notificationOf(AncsNotification fetched, String appName) {
    final event = fetched.event;

    return IphoneNotification(
      uid: fetched.uid,
      appId: fetched.appId,
      appName: appName,
      title: fetched.title,
      subtitle: fetched.subtitle,
      message: fetched.message,
      date: fetched.date,
      category: event.category,
      isSilent: event.isSilent,
      isUpdate: _shown.contains(fetched.uid),
      hasPositiveAction: event.hasPositiveAction,
      hasNegativeAction: event.hasNegativeAction,
    );
  }
}
