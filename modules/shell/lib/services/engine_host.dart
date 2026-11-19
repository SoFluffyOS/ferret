import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:shell/services/device_preferences.dart';
import 'package:transport/transport.dart';

/// Wraps the running [FerretEngine] for the UI: the devices, who is nearby,
/// and pairing requests waiting for an answer.
class EngineHost extends ChangeNotifier {
  EngineHost(this.engine) {
    _subscriptions
      ..add(engine.deviceChanges.listen((_) => notifyListeners()))
      ..add(engine.nearbyChanges.listen((_) => notifyListeners()))
      ..add(engine.pairingPrompts.listen(_onPrompt))
      ..add(
        engine.settings.changes
            .where(DevicePreferences.isOwnKey)
            .listen((_) => notifyListeners()),
      );
  }

  final FerretEngine engine;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<PairingPrompt> _prompts = [];

  /// Connected devices first. One that is reconnecting keeps its place
  /// among them, so a Wi-Fi hiccup doesn't make the list jump. Then pinned
  /// ones, then the one used last (see [DevicePreferences.arrange]).
  List<DeviceStatus> get devices => preferences.arrange(engine.devices);

  DevicePreferences get preferences => DevicePreferences(engine.settings);

  List<DiscoveredPeer> get nearby => engine.nearby;

  int get connectedCount =>
      devices.where((device) => device.isConnected).length;

  /// The oldest pairing request still waiting for the user.
  PairingPrompt? get pendingPrompt {
    _prompts.removeWhere((prompt) => prompt.isDecided);
    return _prompts.firstOrNull;
  }

  DeviceStatus? statusOf(String deviceId) {
    for (final status in devices) {
      if (status.device.id == deviceId) {
        return status;
      }
    }

    return null;
  }

  void _onPrompt(PairingPrompt prompt) {
    _prompts.add(prompt);
    notifyListeners();
    unawaited(prompt.decision.then((_) => notifyListeners()));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }
}
