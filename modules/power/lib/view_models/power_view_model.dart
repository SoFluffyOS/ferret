import 'dart:async';

import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/foundation.dart';
import 'package:power/feature/power_feature.dart';
import 'package:power/models/models.dart';

/// What the Power-ups card, settings and page show, and what they can do.
class PowerViewModel extends ChangeNotifier {
  PowerViewModel(this.feature, {required Future<bool> Function(Uri) openLink})
    : _openLink = openLink {
    _subscription = feature.changes.listen((_) => _notify());
  }

  static final shizukuDownload = Uri.parse(
    'https://shizuku.rikka.app/download/',
  );

  final PowerFeature feature;
  final Future<bool> Function(Uri) _openLink;
  late final StreamSubscription<void> _subscription;

  bool _isBusy = false;
  bool _disposed = false;
  PowerNotice? _notice;

  PowerCapabilities get _power => feature.capabilities;

  PowerStatus get status => feature.status;

  PowerTier get tier => feature.tier;

  /// True while a tap is being worked on, such as waiting for a dialog.
  bool get isBusy => _isBusy;

  /// Why the last tap didn't work.
  PowerNotice? get notice => _notice;

  bool get shizukuEnabled => _power.shizukuEnabled;

  bool get rootEnabled => _power.rootEnabled;

  bool get usesShizuku => shizukuEnabled && status.shizuku == .ready;

  bool get usesRoot => tier == .root;

  /// What the home card asks for, or null when there is nothing to ask.
  PowerPrompt? get prompt {
    final status = this.status;
    if (!status.supported || tier != .standard) {
      return null;
    }

    if (shizukuEnabled) {
      return switch (status.shizuku) {
        .notAuthorized => .shizukuRevoked,
        _ => .shizukuStopped,
      };
    }

    if (rootEnabled) {
      return .rootLost;
    }

    if (feature.settings.cardDismissed) {
      return null;
    }

    return switch (status.shizuku) {
      .notRunning => .startShizuku,
      .notAuthorized || .ready => .allowShizuku,
      .notInstalled => switch (status.root) {
        .notFound => null,
        _ => .useRoot,
      },
    };
  }

  bool isOn(LadderRung rung) => switch (rung) {
    .basic => true,
    .notifications => status.notificationAccess,
    .messagesAndCalls => status.messagesAndCalls,
    .shizuku => tier != .standard,
    .root => tier == .root,
  };

  /// Reads the phone again, such as when the user comes back to Ferret.
  Future<void> refresh() => _power.refresh();

  Future<void> getShizuku() => _run(() async {
    final opened = await _openLink(shizukuDownload);
    return _noticeUnless(opened, .linkFailed);
  });

  Future<void> openShizuku() => _run(() async {
    final opened = await _power.openShizuku();
    return _noticeUnless(opened, .shizukuNotOpened);
  });

  Future<void> allowShizuku() => _run(() async {
    final allowed = await feature.allowShizuku();
    return _noticeUnless(allowed, .shizukuRefused);
  });

  Future<void> stopUsingShizuku() => _run(() async {
    await feature.stopUsingShizuku();
    return null;
  });

  Future<void> useRoot() => _run(() async {
    final allowed = await feature.useRoot();
    return _noticeUnless(allowed, .rootRefused);
  });

  Future<void> stopUsingRoot() => _run(() async {
    await feature.stopUsingRoot();
    return null;
  });

  /// Turns notification access on through the active tier, or opens the
  /// system setting when there is none.
  Future<void> turnOnNotificationAccess() => _run(() async {
    if (tier == .standard) {
      final opened = await _power.openNotificationAccessSettings();
      return _noticeUnless(opened, .settingsNotOpened);
    }

    final granted = await _power.grant(.notificationAccess);
    return _noticeUnless(granted, .grantFailed);
  });

  Future<void> allowBackgroundRunning() => _run(() async {
    final granted = await _power.grant(.batteryUnrestricted);
    return _noticeUnless(granted, .grantFailed);
  });

  Future<void> openAppInfo() => _run(() async {
    final opened = await _power.openAppSettings();
    return _noticeUnless(opened, .settingsNotOpened);
  });

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  PowerNotice? _noticeUnless(bool worked, PowerNotice notice) =>
      switch (worked) {
        true => null,
        false => notice,
      };

  Future<void> _run(Future<PowerNotice?> Function() action) async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    _notice = null;
    _notify();

    try {
      _notice = await action();
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }
}
