import 'dart:async';
import 'dart:io';

import 'package:ferret_system/src/messages.g.dart';

/// Finds network changes and wake from sleep by looking every [interval],
/// for desktops without a native watcher. Sleep shows as a gap in the clock:
/// timers don't run while the machine sleeps.
class PollingNetworkWatcher {
  PollingNetworkWatcher({
    this.interval = const Duration(seconds: 10),
    Future<List<String>> Function()? addresses,
    DateTime Function()? clock,
  }) : _addresses = addresses ?? _localAddresses,
       _clock = clock ?? DateTime.now;

  final Duration interval;
  final Future<List<String>> Function() _addresses;
  final DateTime Function() _clock;
  final StreamController<NetworkChange> _changes = .broadcast();

  Timer? _timer;
  DateTime? _lastCheck;
  List<String>? _lastAddresses;
  bool _checking = false;

  Stream<NetworkChange> get changes => _changes.stream;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) {
      return;
    }

    _timer = .periodic(interval, (_) => unawaited(check()));
    unawaited(check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastCheck = null;
    _lastAddresses = null;
  }

  /// Looks once. The first look only remembers how things are.
  Future<void> check() async {
    if (_checking) {
      return;
    }

    _checking = true;
    try {
      final now = _clock();
      final addresses = [...await _addresses()]..sort();
      final (lastCheck, lastAddresses) = (_lastCheck, _lastAddresses);
      _lastCheck = now;
      _lastAddresses = addresses;

      if (lastCheck != null && now.difference(lastCheck) > interval * 3) {
        _changes.add(.wake);
      }

      if (lastAddresses == null || _same(lastAddresses, addresses)) {
        return;
      }

      _changes.add(_changeFrom(lastAddresses, addresses));
    } finally {
      _checking = false;
    }
  }

  Future<void> dispose() async {
    stop();
    await _changes.close();
  }

  NetworkChange _changeFrom(List<String> before, List<String> after) {
    if (after.isEmpty) {
      return .lost;
    }

    if (before.isEmpty) {
      return .available;
    }

    return .changed;
  }

  bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }

  static Future<List<String>> _localAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return [
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback && !address.isLinkLocal)
              '${interface.name} ${address.address}',
      ];
    } on Object {
      return const [];
    }
  }
}
