import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:shell/services/device_preferences.dart';
import 'package:shell/services/device_successors.dart';
import 'package:shell/services/settled_use.dart';
import 'package:shell/services/whats_new.dart';
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
            .where(
              (key) =>
                  DevicePreferences.isOwnKey(key) ||
                  key == DeviceSuccessors.keptKey,
            )
            .listen((_) => notifyListeners()),
      )
      ..add(
        engine.settings.changes
            .where((key) => key == DevicePreferences.lastUsedKey)
            .listen((_) => _use.used()),
      );
  }

  final FerretEngine engine;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<PairingPrompt> _prompts = [];
  late final SettledUse _use = SettledUse(
    engine.settings,
    onSettled: notifyListeners,
  );

  /// Connected devices first. One that is reconnecting keeps its place
  /// among them, so a Wi-Fi hiccup doesn't make the list jump. Then pinned
  /// ones, then the one used last (see [DevicePreferences.arrange]). A
  /// device just used moves up a little later (see [SettledUse]).
  List<DeviceStatus> get devices =>
      preferences.arrange(engine.devices, lastUsed: _use.lastUsed);

  /// Moves recently used devices up now, such as when the list is put away.
  void settleOrder() => _use.settle();

  DevicePreferences get preferences => DevicePreferences(engine.settings);

  /// Newly paired devices that look like they replace an older namesake.
  List<Successor> get successors =>
      DeviceSuccessors(engine.settings).find(engine.devices);

  /// Lets [successor]'s new device take the old one's place: name here,
  /// pin, what it may use; the old one is forgotten everywhere.
  Future<void> replace(Successor successor) async {
    final oldId = successor.old.id;
    final newId = successor.replacement.id;

    await preferences.inherit(oldId, newId: newId);
    await engine.replace(oldId, newId: newId);
  }

  Future<void> keepBoth(Successor successor) =>
      DeviceSuccessors(engine.settings).keepBoth(successor.replacement.id);

  /// The version Ferret was just updated to, for this run only, until the
  /// person opens or waves off what's new.
  late String? updatedTo = WhatsNew(engine.settings).takeUpdate(
    appVersion: engine.device.appVersion,
    hasPaired: engine.trustStore.devices.isNotEmpty,
  );

  void dismissWhatsNew() {
    updatedTo = null;
    notifyListeners();
  }

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
    _use.dispose();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }
}
