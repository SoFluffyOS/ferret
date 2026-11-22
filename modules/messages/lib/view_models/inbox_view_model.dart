import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
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
        .listen((_) {
          _searchIndex = null;
          _notify();
        });
  }

  final String deviceId;
  final String phoneName;
  final MessageLibrary _library;
  late final StreamSubscription<LibraryEvent> _subscription;

  int? _selectedThreadId;
  String _query = '';
  Map<int, String>? _searchIndex;
  bool _loadingMore = false;
  bool _loadFailed = false;
  bool _disposed = false;

  MessageLibrary get library => _library;

  PhoneState get phone => _library.phone(deviceId);

  List<Conversation> get conversations {
    final all = _library.cache(deviceId).conversations;
    if (!isSearching) {
      return all;
    }

    final index = _searchIndex ??= _indexOf(all);
    return [
      for (final conversation in all)
        if (_matches(conversation, index[conversation.threadId.toInt()] ?? ''))
          conversation,
    ];
  }

  /// What the search box holds; empty when not searching.
  String get query => _query;

  bool get isSearching => _query.trim().isNotEmpty;

  /// How many conversations a search looks through: the ones on this
  /// computer, which grow as older ones load.
  int get searchedCount => _library.cache(deviceId).conversations.length;

  /// Finds conversations by name, number, or words in their texts,
  /// ignoring case and accents: "nguyen" finds "Nguyễn".
  void search(String query) {
    if (query == _query) {
      return;
    }

    _query = query;
    _notify();
  }

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

  bool _matches(Conversation conversation, String folded) {
    final words = SearchText.fold(_query).split(RegExp(r'\s+'));
    final digitsHay = _digits(
      conversation.participants
          .map((participant) => participant.address)
          .join(' '),
    );
    return words.where((word) => word.isNotEmpty).every((word) {
      if (folded.contains(word)) {
        return true;
      }

      // "0901 234 567" finds "+84 901 234 567": the national 0 drops out.
      final digits = _digits(word).replaceFirst(RegExp('^0+'), '');
      return digits.length >= _minDigits && digitsHay.contains(digits);
    });
  }

  Map<int, String> _indexOf(List<Conversation> conversations) {
    final cache = _library.cache(deviceId);
    return {
      for (final conversation in conversations)
        conversation.threadId.toInt(): SearchText.fold(
          [
            conversation.title,
            for (final participant in conversation.participants) ...[
              participant.name,
              participant.address,
            ],
            conversation.snippet,
            for (final message in cache.messages(
              conversation.threadId.toInt(),
            ))
              message.body,
          ].join('\n'),
        ),
    };
  }

  static const _minDigits = 3;

  static String _digits(String text) => text.replaceAll(RegExp(r'\D'), '');

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
