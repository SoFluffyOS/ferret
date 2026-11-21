import 'dart:math' as math;

/// Keeps a device that was turned down from asking to pair again right
/// away, so a neighbour can't fill the screen with requests. After a no, or
/// a request nobody answered, its address and its device id wait [first];
/// each further no doubles the wait, up to [longest]. A quiet [forgetAfter]
/// starts it over.
class PairingCooldown {
  PairingCooldown({
    this.first = const Duration(seconds: 60),
    this.longest = const Duration(minutes: 10),
    this.forgetAfter = const Duration(hours: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration first;
  final Duration longest;
  final Duration forgetAfter;
  final DateTime Function() _now;

  /// Bounds memory when many addresses or ids come and go.
  static const _maxEntries = 256;

  final Map<String, _Strikes> _entries = {};

  /// Whether a request from [host] or [deviceId] is turned away for now.
  bool holds({required String host, required String deviceId}) {
    final now = _now();
    return [
      _entries[_hostKey(host)],
      _entries[_idKey(deviceId)],
    ].any((strikes) => strikes != null && now.isBefore(strikes.until));
  }

  /// Notes that a request from [host] and [deviceId] was turned down or
  /// went unanswered.
  void strike({required String host, required String deviceId}) {
    final now = _now();
    _prune(now);
    for (final key in [_hostKey(host), _idKey(deviceId)]) {
      final count = switch (_entries[key]) {
        final strikes? when now.difference(strikes.at) < forgetAfter =>
          strikes.count + 1,
        _ => 1,
      };
      final wait = first * math.pow(2, math.min(count - 1, 16)).toInt();
      _entries[key] = _Strikes(
        count: count,
        at: now,
        until: now.add(switch (wait > longest) {
          true => longest,
          false => wait,
        }),
      );
    }
  }

  void _prune(DateTime now) {
    _entries.removeWhere(
      (_, strikes) => now.difference(strikes.at) >= forgetAfter,
    );
    while (_entries.length >= _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  static String _hostKey(String host) => 'host:$host';
  static String _idKey(String deviceId) => 'id:$deviceId';
}

class _Strikes {
  const _Strikes({required this.count, required this.at, required this.until});

  final int count;
  final DateTime at;
  final DateTime until;
}
