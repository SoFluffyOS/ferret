import 'dart:async';

import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/foundation.dart';
import 'package:iphone/feature/iphone_feature.dart';
import 'package:iphone/models/models.dart';

/// What the home card shows: the iPhone's player with its controls, or what
/// stands in the way of the link.
class IphoneViewModel extends ChangeNotifier {
  IphoneViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => _onChanged());
  }

  final IphoneFeature feature;
  late final StreamSubscription<void> _subscription;
  bool _commandFailed = false;
  bool _disposed = false;

  LinkState get link => feature.link;

  AmsState get media => feature.media;

  bool get isEnabled => feature.isSupported && feature.settings.enabled;

  /// The iPhone is connected and has something in a player.
  bool get showsPlayer =>
      isEnabled && link.isConnected && link.hasMedia && media.hasTrack;

  /// The link needs the person before it can work.
  bool get showsProblem => isEnabled && link.needsAttention;

  bool get hasCard => showsPlayer || showsProblem;

  /// The last control didn't reach the iPhone.
  bool get commandFailed => _commandFailed;

  Future<void> send(AmsCommand command) async {
    final sent = await feature.sendMedia(command);
    _commandFailed = !sent;
    _notify();
  }

  Future<void> retry() => feature.refresh(force: true);

  Future<void> openBluetoothSettings() => feature.openBluetoothSettings();

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _onChanged() {
    if (!link.isConnected) {
      _commandFailed = false;
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
