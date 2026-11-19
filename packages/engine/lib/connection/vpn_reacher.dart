import 'dart:async';

/// Keeps trying to reach devices over the user's VPN while the local
/// network doesn't find them, waiting longer after each miss.
class VpnReacher {
  VpnReacher({required this.attempt, this.delays = defaultDelays});

  /// The waits before each try. The first one leaves time for the local
  /// network to find the device; the last one repeats until it answers.
  static const defaultDelays = [
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  /// Tries to reach a device once and says whether there is nothing left
  /// to try: it is connected, or no longer to be reached this way.
  final Future<bool> Function(String deviceId) attempt;
  final List<Duration> delays;

  final Map<String, int> _runs = {};
  int _nextRun = 0;

  /// The devices it is trying to reach.
  Set<String> get reaching => Set.unmodifiable(_runs.keys);

  /// Starts trying to reach [deviceId], from the first wait again when it
  /// already was.
  void reach(String deviceId) {
    final run = _nextRun++;
    _runs[deviceId] = run;
    unawaited(_loop(deviceId, run));
  }

  /// Stops trying to reach [deviceId], such as once it connected.
  void stop(String deviceId) => _runs.remove(deviceId);

  void stopAll() => _runs.clear();

  Future<void> _loop(String deviceId, int run) async {
    var tries = 0;
    while (_runs[deviceId] == run) {
      final wait = delays[tries.clamp(0, delays.length - 1)];
      tries++;
      await Future<void>.delayed(wait);
      if (_runs[deviceId] != run) {
        return;
      }

      final bool done;
      try {
        done = await attempt(deviceId);
      } on Object {
        continue;
      }

      if (done && _runs[deviceId] == run) {
        _runs.remove(deviceId);
      }
    }
  }
}
