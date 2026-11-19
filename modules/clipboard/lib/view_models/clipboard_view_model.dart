import 'dart:async';

import 'package:clipboard/feature/clipboard_feature.dart';
import 'package:clipboard/models/models.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter/foundation.dart';

/// What the clipboard card and settings show, and what they can do.
class ClipboardViewModel extends ChangeNotifier {
  ClipboardViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final ClipboardFeature feature;
  late final StreamSubscription<void> _subscription;

  bool _isSending = false;
  String? _copiedId;
  ClipSendResult? _lastResult;
  DateTime? _lastResultAt;

  ClipEntry? get latest => feature.latest;

  /// Newest first.
  List<ClipEntry> get history => feature.history;

  /// The clips that can be copied again, newest first. Private clips are
  /// never listed, not even once they expired.
  List<ClipEntry> get recentClips => [
    for (final entry in feature.history)
      if (entry.hasContent && !entry.isSensitive) entry,
  ];

  /// The clip last put back on the clipboard from Recent clips.
  String? get copiedId => _copiedId;

  /// Whether [entry] waits for a device to connect.
  bool isWaiting(ClipEntry entry) => feature.isWaiting(entry);

  /// Whether a connected device would get a copy made now.
  bool get hasPeers => feature.hasPeers;

  int get historyCount => feature.history.length;

  ClipboardAccess get access => feature.access;

  /// Copies made in other apps can't be noticed here, so people send by hand.
  bool get needsManualSend =>
      !access.watchesOtherApps && !feature.sendsInBackground;

  /// Copies made on this device go to the others without a tap.
  bool get sendsOnItsOwn => autoSend && !needsManualSend;

  /// Background sending is on, but the power-up it needs is gone.
  bool get lostBackgroundSend =>
      access == .foreground &&
      autoSend &&
      backgroundSend &&
      !canSendInBackground;

  /// An Android power-up is on, so background sending can be offered.
  bool get canSendInBackground => feature.canSendInBackground;

  /// The power-up is on and only the switch is missing.
  bool get offersBackgroundSend =>
      canSendInBackground && autoSend && !backgroundSend;

  bool get backgroundSend => _settings.backgroundSend;

  bool get isSending => _isSending;

  /// The outcome of the last "Send clipboard" tap.
  ClipSendResult? get lastResult => _lastResult;

  /// When [lastResult] came in.
  DateTime? get lastResultAt => _lastResultAt;

  ClipboardSettings get _settings => feature.settings;

  bool get autoSend => _settings.autoSend;

  bool get autoReceive => _settings.autoReceive;

  bool get syncImages => _settings.syncImages;

  bool get syncSensitive => _settings.syncSensitive;

  int get maxImageMegabytes => _settings.maxImageBytes ~/ (1024 * 1024);

  int get expiryMinutes => switch (_settings.expiry.inMinutes) {
    final minutes when minutes > 0 => minutes,
    _ => 1,
  };

  /// Sends what is on this device's clipboard, and says how it went. Null
  /// while an earlier send is still under way.
  Future<ClipSendResult?> sendClipboard({String? toDeviceId}) async {
    if (_isSending) {
      return null;
    }

    _isSending = true;
    _lastResult = null;
    notifyListeners();

    try {
      final result = await feature.sendClipboard(toDeviceId: toDeviceId);
      _lastResult = result;
      _lastResultAt = DateTime.now();
      return result;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> copy(ClipEntry entry) => feature.copyToClipboard(entry);

  /// Puts [entry] back on this device's clipboard from Recent clips, and
  /// marks it as the one copied.
  Future<bool> copyAgain(ClipEntry entry) async {
    final copied = await feature.copyToClipboard(entry);
    if (!copied) {
      return false;
    }

    _copiedId = entry.id;
    notifyListeners();
    return true;
  }

  Future<void> setAutoSend(bool value) => _settings.setAutoSend(value);

  Future<void> setBackgroundSend(bool value) =>
      _settings.setBackgroundSend(value);

  Future<void> setAutoReceive(bool value) => _settings.setAutoReceive(value);

  Future<void> setSyncImages(bool value) => _settings.setSyncImages(value);

  Future<void> setSyncSensitive(bool value) =>
      _settings.setSyncSensitive(value);

  void clearHistory() {
    _lastResult = null;
    feature.clearHistory();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
