import 'package:feature_kit/feature_kit.dart';

/// Shows one notice for one piece of news. When two features tell the same
/// thing (see [NoticeEcho]), such as a text that Messages and the mirrored
/// Google Messages notification both see, the one that wins stays and the
/// other doesn't pop up. Either may arrive first.
class EchoNotifier implements LocalNotifier {
  EchoNotifier(this._notifier, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// How long two notices count as the same news.
  static const window = Duration(minutes: 2);

  final LocalNotifier _notifier;
  final DateTime Function() _now;
  final Map<String, _Shown> _recent = {};

  @override
  Future<void> show(LocalNotice notice) async {
    final echo = notice.echo;
    if (echo == null || echo.keys.isEmpty) {
      return _notifier.show(notice);
    }

    final now = _now();
    _recent.removeWhere((_, shown) => now.difference(shown.at) > window);
    final twins = [
      for (final MapEntry(key: id, value: shown) in _recent.entries)
        if (id != notice.id && shown.keys.any(echo.keys.contains)) (id, shown),
    ];

    if (twins.any((twin) => twin.$2.wins && twin.$2.showing) && !echo.wins) {
      _recent[notice.id] = _Shown(echo.keys, echo.wins, now, showing: false);
      return;
    }

    for (final (id, shown) in twins) {
      if (echo.wins && !shown.wins && shown.showing) {
        _recent.remove(id);
        await _notifier.cancel(id);
      }
    }

    _recent[notice.id] = _Shown(echo.keys, echo.wins, now, showing: true);
    return _notifier.show(notice);
  }

  @override
  Future<void> cancel(String id) {
    _recent.remove(id);
    return _notifier.cancel(id);
  }

  @override
  Stream<NoticeResponse> get responses => _notifier.responses;
}

class _Shown {
  _Shown(this.keys, this.wins, this.at, {required this.showing});

  final Set<String> keys;
  final bool wins;
  final DateTime at;
  final bool showing;
}
