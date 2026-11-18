import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';
import 'package:protocol/messages.dart';

/// One phone's conversation list on a computer: what is saved shows at once,
/// the newest page syncs when the phone connects, older pages load on scroll.
class InboxViewModel extends ChangeNotifier {
  InboxViewModel({
    required MessageLibrary library,
    required this.deviceId,
    required this.phoneName,
    int? initialThreadId,
  }) : _library = library,
       _selectedThreadId = initialThreadId {
    _subscription = library.events
        .where((event) => event.deviceId == deviceId)
        .listen((_) => _notify());
  }

  final String deviceId;
  final String phoneName;
  final MessageLibrary _library;
  late final StreamSubscription<LibraryEvent> _subscription;

  int? _selectedThreadId;
  bool _loadingMore = false;
  bool _loadFailed = false;
  bool _disposed = false;

  MessageLibrary get library => _library;

  PhoneState get phone => _library.phone(deviceId);

  List<Conversation> get conversations =>
      _library.cache(deviceId).conversations;

  bool get hasMore => _library.cache(deviceId).hasMoreConversations;

  bool get loadingMore => _loadingMore;

  /// The last load or retry failed; show why and a retry button.
  bool get loadFailed => _loadFailed;

  int get unreadTotal => _library.unreadTotal(deviceId);

  int? get selectedThreadId => _selectedThreadId;

  void select(int? threadId) {
    if (threadId == _selectedThreadId) {
      return;
    }

    _selectedThreadId = threadId;
    _notify();
  }

  /// Loads the next page of older conversations, once at a time.
  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || phone.readiness != .ready) {
      return;
    }

    _loadingMore = true;
    _notify();

    final ok = await _library.loadOlderConversations(deviceId);
    _loadingMore = false;
    _loadFailed = !ok;
    _notify();
  }

  Future<void> retry() async {
    _loadFailed = false;
    _notify();

    final ok = await _library.refresh(deviceId);
    _loadFailed = !ok;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
