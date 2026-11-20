import 'dart:async';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:remote_input/feature/remote_input_feature.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/services.dart';

/// This Mac's keyboard and mouse on other computers: the Settings line,
/// what Activity shows while they are away, and why a switch didn't work.
class ScreenSwitchViewModel extends ChangeNotifier {
  ScreenSwitchViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final RemoteInputFeature feature;
  late final StreamSubscription<void> _subscription;

  ScreenSwitch? get _switch => feature.screenSwitch;

  bool get isAvailable => _switch != null;

  bool get enabled => _switch?.enabled ?? false;

  ScreenSwitchState get state => _switch?.state ?? .home;

  /// Null before the first check.
  CaptureAccess? get access => _switch?.access;

  bool get keysTaken => _switch?.keysTaken ?? false;

  /// On, and macOS still holds back access it needs.
  bool get needsAccess => enabled && !(access?.isGranted ?? true);

  Future<void> setEnabled(bool value) async => _switch?.setEnabled(value);

  Future<void> requestAccess() async => _switch?.requestAccess();

  Future<void> checkAgain() async => _switch?.checkAccess();

  Future<void> home() async => _switch?.home();

  void dismissProblem() => _switch?.dismissProblem();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
