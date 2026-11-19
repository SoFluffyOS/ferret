import 'dart:async';

import 'package:ferret_system/src/session/screen_session_source.dart';

/// Asks [probe] every [interval], for systems that only answer when asked,
/// such as Windows.
class PollingSessionSource implements ScreenSessionSource {
  PollingSessionSource({
    required bool Function() probe,
    this.interval = const Duration(seconds: 2),
  }) : _probe = probe;

  final Duration interval;
  final bool Function() _probe;
  final StreamController<bool> _changes = .broadcast();
  Timer? _timer;

  @override
  Future<bool> isActive() async => _probe();

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  Future<void> start() async {
    _timer ??= .periodic(interval, (_) => _changes.add(_probe()));
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}
