import 'dart:async';

import 'package:calls/calls.dart';
import 'package:engine/engine.dart';
import 'package:media/media.dart';

/// Pauses the players on this device while a call rings or goes on, and
/// plays again only the ones it paused once the call ends. Calls and Media
/// never import each other, so the app joins them here.
class CallMediaPause {
  CallMediaPause({
    required Stream<bool> inCallChanges,
    required bool Function() inCall,
    required bool Function() enabled,
    required Future<List<String>> Function() pause,
    required Future<void> Function(List<String> playerIds) resume,
  }) : _inCallChanges = inCallChanges,
       _inCall = inCall,
       _enabled = enabled,
       _pause = pause,
       _resume = resume;

  final Stream<bool> _inCallChanges;
  final bool Function() _inCall;
  final bool Function() _enabled;
  final Future<List<String>> Function() _pause;
  final Future<void> Function(List<String> playerIds) _resume;

  StreamSubscription<bool>? _subscription;
  Future<void> _queue = Future.value();

  /// The players paused for the current call, null when none was paused.
  List<String>? _paused;

  /// Joins the engine's Calls and Media features, or returns null when
  /// either is missing.
  static CallMediaPause? attach(FerretEngine engine) {
    final calls = engine.feature<CallsFeature>();
    final media = engine.feature<MediaFeature>();
    if (calls == null || media == null) {
      return null;
    }

    return CallMediaPause(
      inCallChanges: calls.inCallChanges,
      inCall: () => calls.inCall,
      enabled: () => media.pauseOnCall,
      pause: media.pauseLocalPlayback,
      resume: media.resumeLocalPlayback,
    )..start();
  }

  void start() {
    _subscription ??= _inCallChanges.listen(_onInCall);
    if (_inCall()) {
      _onInCall(true);
    }
  }

  /// Waits for a pause or resume on its way, such as in tests.
  Future<void> get settled => _queue;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  // Pausing and resuming wait on the platform; running them one after the
  // other keeps a quick call from resuming before the pause finished.
  void _onInCall(bool inCall) {
    _queue = _queue.then((_) => _apply(inCall));
  }

  Future<void> _apply(bool inCall) async {
    if (inCall) {
      await _pauseForCall();
      return;
    }

    final paused = _paused;
    _paused = null;
    if (paused == null || paused.isEmpty) {
      return;
    }

    await _resume(paused);
  }

  Future<void> _pauseForCall() async {
    if (_paused != null || !_enabled()) {
      return;
    }

    _paused = await _pause();
  }
}
