import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:shell/services/device_preferences.dart';

/// How often each action was used with each device, so the one used most
/// moves first on that device's row once it has been used [learnsAfter]
/// times. Counts live in settings under `shell.device_actions.<id>`, as a
/// map from action id to uses, and never leave this device.
class DeviceActionUsage {
  const DeviceActionUsage(this._settings);

  final SettingsStore _settings;

  /// Uses before an action may move first.
  static const learnsAfter = 3;

  /// What every device's settings key starts with.
  static const keyPrefix = 'shell.device_actions.';

  static String keyFor(String deviceId) => '$keyPrefix$deviceId';

  /// Uses of each action with [deviceId], by action id.
  Map<String, int> countsFor(String deviceId) {
    final stored = _settings.get<Map<String, dynamic>>(keyFor(deviceId));
    if (stored == null) {
      return const {};
    }

    return {
      for (final MapEntry(:key, :value) in stored.entries)
        if (value case final int count) key: count,
    };
  }

  Future<void> record(String deviceId, String actionId) async {
    final counts = countsFor(deviceId);
    final updated = {...counts, actionId: (counts[actionId] ?? 0) + 1};

    await _settings.set(keyFor(deviceId), updated);
    await DevicePreferences(_settings).markUsed(deviceId);
  }

  /// [actions] with the most used one first, once it was used
  /// [learnsAfter] times; a tie keeps the order they came in. Every
  /// action counts its use with [deviceId] when pressed.
  List<FeatureAction> arrange(String deviceId, List<FeatureAction> actions) {
    final learned = learnedOrder(actions, countsFor(deviceId));

    return [for (final action in learned) _counting(deviceId, action)];
  }

  /// [actions] with the one used most in [counts] moved first, if it was
  /// used at least [learnsAfter] times. Only that one moves: the others
  /// keep their places, so the row doesn't reshuffle with every use.
  static List<FeatureAction> learnedOrder(
    List<FeatureAction> actions,
    Map<String, int> counts,
  ) {
    FeatureAction? favourite;
    var most = learnsAfter - 1;
    for (final action in actions) {
      final uses = counts[action.id] ?? 0;
      if (uses > most) {
        favourite = action;
        most = uses;
      }
    }
    if (favourite == null) {
      return actions;
    }

    return [
      favourite,
      for (final action in actions)
        if (!identical(action, favourite)) action,
    ];
  }

  FeatureAction _counting(String deviceId, FeatureAction action) {
    final actionId = action.id;
    final onPressed = action.onPressed;
    if (actionId == null || onPressed == null) {
      return action;
    }

    return FeatureAction(
      id: actionId,
      label: action.label,
      icon: action.icon,
      homeOrder: action.homeOrder,
      sectionId: action.sectionId,
      onPressed: () {
        unawaited(record(deviceId, actionId));
        onPressed();
      },
    );
  }
}
