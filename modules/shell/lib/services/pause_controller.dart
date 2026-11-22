import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';

/// Pauses Ferret: stops listening and connecting until [resume] or the
/// chosen time runs out.
class PauseController extends ChangeNotifier {
  PauseController(this._engine);

  final FerretEngine _engine;
  Timer? _timer;
  DateTime? _until;
  bool _paused = false;
  bool _disposed = false;

  bool get isPaused => _paused;

  /// When the pause ends by itself, or null for "until I resume".
  DateTime? get until => _until;

  Future<void> pause({Duration? duration}) async {
    _timer?.cancel();
    _until = switch (duration) {
      final duration? => DateTime.now().add(duration),
      null => null,
    };
    if (duration != null) {
      _timer = Timer(duration, () => unawaited(resume()));
    }

    if (!_paused) {
      _paused = true;
      await _engine.stop();
    }

    _notify();
  }

  Future<void> resume() async {
    _timer?.cancel();
    _timer = null;
    _until = null;
    if (!_paused) {
      return;
    }

    _paused = false;
    await _engine.start();
    _notify();
  }

  /// Starting or stopping the engine takes a while; the app may have shut
  /// this down meanwhile, as quitting from the menu does.
  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
