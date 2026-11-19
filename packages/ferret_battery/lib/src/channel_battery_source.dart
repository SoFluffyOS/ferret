import 'package:ferret_battery/src/battery_level.dart';
import 'package:ferret_battery/src/battery_source.dart';
import 'package:flutter/services.dart';

/// Android and iOS: the system says when the level changes, so there is
/// no polling on a phone.
class ChannelBatterySource implements BatterySource {
  static const _methods = MethodChannel('io.sofluffy.ferret_battery');
  static const _events = EventChannel('io.sofluffy.ferret_battery/changes');

  @override
  Future<BatteryLevel?> read() async {
    try {
      return levelOf(await _methods.invokeMethod<Object?>('read'));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Stream<BatteryLevel?> get changes =>
      _events.receiveBroadcastStream().map(levelOf);

  /// `{percent: 62, charging: true}` from the platform, or null.
  static BatteryLevel? levelOf(Object? value) => switch (value) {
    {'percent': final int percent, 'charging': final bool charging}
        when percent >= 0 =>
      BatteryLevel(percent.clamp(0, 100), charging: charging),
    _ => null,
  };
}
