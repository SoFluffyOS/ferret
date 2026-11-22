import 'dart:async';

import 'package:clock/clock.dart';

/// How often a device repeats its announce: [interval] while there may be
/// someone to find, [relaxedInterval] once every paired device is
/// connected and nothing is left to find. Each announce wakes every
/// device on the network, a phone's Wi-Fi radio included, so repeating
/// it for nobody is battery spent for nothing.
class AnnouncePacer {
  AnnouncePacer({
    required this.interval,
    required this.relaxedInterval,
  });

  final Duration interval;
  final Duration relaxedInterval;

  void Function()? _onTick;
  Timer? _timer;
  bool _relaxed = false;

  bool get isRelaxed => _relaxed;

  bool get isRunning => _timer != null;

  Duration get current => switch (_relaxed) {
    true => relaxedInterval,
    false => interval,
  };

  void start(void Function() onTick) {
    _onTick = onTick;
    _restart();
  }

  /// Back to [interval] calls [onTick] at once, since a device just went
  /// missing and the network should hear about this one now.
  void setRelaxed(bool relaxed) {
    if (relaxed == _relaxed) {
      return;
    }

    _relaxed = relaxed;
    if (_timer == null) {
      return;
    }

    _restart();
    if (!relaxed) {
      _onTick?.call();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _onTick = null;
  }

  void _restart() {
    _timer?.cancel();
    final onTick = _onTick;
    if (onTick == null) {
      return;
    }

    _timer = .periodic(current, (_) => onTick());
  }
}

/// Lets one thing through per key within [gap]. A device's announce
/// arrives twice, once by multicast and once by broadcast, and both
/// would be answered and passed on.
class RepeatGate {
  RepeatGate({this.gap = const Duration(seconds: 2)});

  final Duration gap;
  final Map<String, DateTime> _passed = {};

  /// Whether [key] goes through now. Remembers it when it does.
  bool pass(String key) {
    final now = clock.now();
    _passed.removeWhere((_, at) => now.difference(at) >= gap);
    if (_passed.containsKey(key)) {
      return false;
    }

    _passed[key] = now;
    return true;
  }
}
