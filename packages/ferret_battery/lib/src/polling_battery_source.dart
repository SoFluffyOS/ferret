import 'dart:async';

import 'package:ferret_battery/src/battery_level.dart';
import 'package:ferret_battery/src/battery_source.dart';

/// Reads with [_read] while someone listens, every [interval], and passes
/// on only what changed.
class PollingBatterySource implements BatterySource {
  PollingBatterySource(
    this._read, {
    this.interval = const Duration(minutes: 2),
  });

  final Future<BatteryLevel?> Function() _read;
  final Duration interval;

  @override
  Future<BatteryLevel?> read() async {
    try {
      return await _read();
    } on Object {
      return null;
    }
  }

  @override
  Stream<BatteryLevel?> get changes {
    Timer? timer;
    BatteryLevel? last;
    late final StreamController<BatteryLevel?> controller;

    Future<void> poll() async {
      final level = await read();
      if (level == last || controller.isClosed) {
        return;
      }

      last = level;
      controller.add(level);
    }

    controller = StreamController<BatteryLevel?>(
      onListen: () => timer = Timer.periodic(interval, (_) => poll()),
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}
