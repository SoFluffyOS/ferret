import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';

/// One quiet notice when another device runs low, such as "Pixel 7 is at
/// 15%". Once per discharge: it says it again only after that device
/// charged or went back above [resetPercent].
class LowBatteryNotices {
  LowBatteryNotices({
    required Stream<List<DeviceStatus>> devices,
    required LocalNotifier notifier,
    required SettingsStore settings,
    required String Function(String deviceId) nameOf,
    ShellLocalizations Function()? l10n,
  }) : _devices = devices,
       _notifier = notifier,
       _settings = settings,
       _nameOf = nameOf,
       _l10n =
           l10n ??
           (() => lookupShellLocalizations(
             AppLocale.pick(ShellLocalizations.supportedLocales),
           ));

  /// Setting: whether the notice shows at all. On by default.
  static const enabledKey = 'battery.low_notice';

  static const lowPercent = 15;
  static const resetPercent = 20;

  final Stream<List<DeviceStatus>> _devices;
  final LocalNotifier _notifier;
  final SettingsStore _settings;
  final String Function(String deviceId) _nameOf;
  final ShellLocalizations Function() _l10n;
  final Set<String> _told = {};
  StreamSubscription<List<DeviceStatus>>? _subscription;

  static bool isOn(SettingsStore settings) =>
      settings.get<bool>(enabledKey) ?? true;

  void start() {
    _subscription ??= _devices.listen((devices) => unawaited(_check(devices)));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _check(List<DeviceStatus> devices) async {
    for (final status in devices) {
      final battery = status.battery;
      final deviceId = status.device.id;
      if (battery == null) {
        continue;
      }

      if (battery.charging || battery.percent > resetPercent) {
        _told.remove(deviceId);
        continue;
      }

      if (battery.percent > lowPercent || !isOn(_settings)) {
        continue;
      }

      if (!_told.add(deviceId)) {
        continue;
      }

      final l10n = _l10n();
      await _notifier.show(
        LocalNotice(
          id: 'battery.low.$deviceId',
          channel: .problems,
          title: l10n.lowBatteryTitle(_nameOf(deviceId), battery.percent),
          body: l10n.lowBatteryBody,
          silent: true,
        ),
      );
    }
  }
}
