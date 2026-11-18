import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';

/// What the phone's card and settings show while computers ask for or see
/// its screen, and what they can do.
class ShareViewModel extends ChangeNotifier {
  ShareViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final MirroringFeature feature;
  late final StreamSubscription<void> _subscription;

  MirrorSource? get _source => feature.source;

  bool get isAvailable => _source != null;

  /// Whether this phone can capture its screen at all.
  bool get canCapture => _source?.support.canCapture ?? false;

  ShareRequest? get pending => _source?.pending;

  ActiveShare? get active => _source?.active;

  MirrorRecord? get lastRecord => _source?.lastRecord;

  bool get enabled => feature.settings.enabled;

  List<MirrorRecord> get history => feature.settings.history;

  bool get hasCard => pending != null || active != null || lastRecord != null;

  Future<void> stop() async => _source?.stop();

  Future<void> setEnabled(bool value) async => _source?.setEnabled(value);

  /// Whether the computer [deviceId] may ask to see this screen.
  bool mayAsk(String deviceId) => !feature.settings.isBlocked(deviceId);

  Future<void> setMayAsk(String deviceId, bool value) async =>
      _source?.setBlocked(deviceId, !value);

  void dismissRecord() => _source?.dismissRecord();

  Future<void> clearHistory() async => _source?.clearHistory();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
