import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:phone_camera/feature/feature.dart';
import 'package:phone_camera/models/models.dart';

/// On a phone: the computers' requests for a picture, for the home card.
class CaptureAsksViewModel extends ChangeNotifier {
  CaptureAsksViewModel(this._feature) {
    _subscription = _feature.askChanges.listen((_) => notifyListeners());
  }

  final CameraFeature _feature;
  late final StreamSubscription<void> _subscription;

  List<CaptureAsk> get asks => _feature.asks;

  String nameOf(String deviceId) => _feature.host.displayNameOf(deviceId);

  Future<void> take(String requestId) => _feature.take(requestId);

  Future<void> decline(String requestId) => _feature.decline(requestId);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
