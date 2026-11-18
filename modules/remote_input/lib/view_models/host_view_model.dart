import 'dart:async';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:remote_input/feature/remote_input_feature.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/services.dart';

/// A device allowed for good, with the name to show.
typedef AllowedDevice = ({String id, String name});

/// What this computer's card, consent dialog and settings show while other
/// devices ask for or hold control, and what they can do.
class HostViewModel extends ChangeNotifier {
  HostViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final RemoteInputFeature feature;
  late final StreamSubscription<void> _subscription;

  ControlHost? get _host => feature.controlHost;

  bool get isAvailable => _host != null;

  ConsentRequest? get pending => _host?.pending;

  ActiveControl? get active => _host?.active;

  PermissionAsk? get permissionAsk => _host?.permissionAsk;

  ControlRecord? get lastRecord => _host?.lastRecord;

  InjectorStatus? get status => _host?.status;

  bool get enabled => feature.settings.enabled;

  List<ControlRecord> get history => feature.settings.history;

  List<AllowedDevice> get allowedDevices => [
    for (final id in feature.settings.allowedDevices)
      (id: id, name: feature.host.trustStore[id]?.name ?? id),
  ];

  bool get hasCard =>
      pending != null ||
      active != null ||
      permissionAsk != null ||
      lastRecord != null;

  Future<void> answer(ConsentChoice choice) async => _host?.answer(choice);

  Future<void> stop() async => _host?.stop();

  Future<void> revoke(String deviceId) async => _host?.revoke(deviceId);

  Future<void> setEnabled(bool value) async => _host?.setEnabled(value);

  Future<void> requestAccess() async => _host?.requestAccess();

  Future<void> openAccessSettings() async => _host?.openAccessSettings();

  Future<void> checkAgain() async => _host?.refreshStatus();

  void dismissRecord() => _host?.dismissRecord();

  void dismissPermissionAsk() => _host?.dismissPermissionAsk();

  Future<void> clearHistory() async => _host?.clearHistory();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
