import 'dart:async';
import 'dart:io';

import 'package:ferret_handoff/src/messages.g.dart';
import 'package:flutter/services.dart';

/// Answers a shared item: true once it was sent to the chosen device.
typedef SharedItemHandler = Future<bool> Function(SharedItem item);

/// Handoff's platform side: the Android share target and assistant, opening
/// links in a given app, and the macOS browser page.
///
/// Calls on platforms that don't have a feature return a neutral answer
/// instead of throwing, so callers don't check the platform themselves.
class FerretHandoff implements HandoffEventsApi {
  FerretHandoff({HandoffHostApi? api, bool? isAndroid, bool? isMacOS})
    : _api = api ?? HandoffHostApi(),
      _isAndroid = isAndroid ?? Platform.isAndroid,
      _isMacOS = isMacOS ?? Platform.isMacOS;

  final HandoffHostApi _api;
  final bool _isAndroid;
  final bool _isMacOS;
  final StreamController<String> _browserDeactivated = .broadcast();
  SharedItemHandler? _onShared;
  bool _listening = false;

  bool get supportsShareTarget => _isAndroid;

  bool get supportsAssistant => _isAndroid;

  bool get supportsBrowserTab => _isMacOS;

  /// Fires with the bundle id of a browser the user just left, once
  /// [setBrowserWatch] is on.
  Stream<String> get browserDeactivated => _browserDeactivated.stream;

  /// Starts taking items from the share sheet and the assistant.
  void listen(SharedItemHandler onShared) {
    _onShared = onShared;
    if (_listening || !(_isAndroid || _isMacOS)) {
      return;
    }

    _listening = true;
    HandoffEventsApi.setUp(this);
  }

  Future<void> setDevices(List<HandoffDevice> devices) async {
    if (!_isAndroid) {
      return;
    }

    await _api.setDevices(devices);
  }

  Future<List<SharedItem>> takePending() async {
    if (!_isAndroid) {
      return const [];
    }

    return _api.takePending();
  }

  /// Opens [uri] in the app [appId]: an Android package or a macOS bundle id.
  Future<bool> openInApp(String uri, String appId) async {
    if (!(_isAndroid || _isMacOS)) {
      return false;
    }

    return _api.openInApp(uri, appId);
  }

  Future<bool> isAssistantEnabled() async {
    if (!_isAndroid) {
      return false;
    }

    return _api.isAssistantEnabled();
  }

  Future<void> openAssistantSettings() async {
    if (!_isAndroid) {
      return;
    }

    await _api.openAssistantSettings();
  }

  /// The current browser page on macOS. Throws a `PlatformException` with
  /// code `denied` when the user refused Automation access.
  Future<BrowserTab?> currentBrowserTab() async {
    if (!_isMacOS) {
      return null;
    }

    return _api.currentBrowserTab();
  }

  Future<BrowserAccess> browserAccess() async {
    if (!_isMacOS) {
      return .unsupported;
    }

    return _api.browserAccess();
  }

  Future<void> setBrowserWatch(bool enabled) async {
    if (!_isMacOS) {
      return;
    }

    await _api.setBrowserWatch(enabled);
  }

  /// Fails while nobody listens yet, so the platform keeps the item and
  /// hands it over through [takePending] instead of dropping it.
  @override
  Future<bool> onShared(SharedItem item) async {
    final handler = _onShared;
    if (handler == null) {
      throw PlatformException(code: 'not-ready');
    }

    return handler(item);
  }

  @override
  void onBrowserDeactivated(String bundleId) =>
      _browserDeactivated.add(bundleId);
}
