import 'dart:async';

import 'package:ferret_calls/src/messages.g.dart';
import 'package:ferret_calls/src/phone_calls.dart';
import 'package:flutter/foundation.dart';

/// [PhoneCalls] on Android, through the plugin.
///
/// Only Android implements it; check [isSupported] first.
class FerretCalls implements PhoneCalls {
  FerretCalls({CallsHostApi? hostApi}) : _hostApi = hostApi ?? CallsHostApi();

  final CallsHostApi _hostApi;

  // One handler per Flutter engine receives the platform's events, so every
  // instance shares it.
  static final StreamController<PlatformPhoneEvent> _events = .broadcast(
    onListen: () => CallsFlutterApi.setUp(_EventRelay(_events)),
    onCancel: () => CallsFlutterApi.setUp(null),
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<PlatformPhoneEvent> get events => _events.stream;

  @override
  Future<PlatformCallPermissions> permissions() => _hostApi.getPermissions();

  @override
  Future<PlatformCallPermissions> requestPermissions() =>
      _hostApi.requestPermissions();

  @override
  Future<bool> hasTelephony() => _hostApi.hasTelephony();

  @override
  Future<void> openAppSettings() => _hostApi.openAppSettings();

  @override
  Future<bool> startMonitoring() => _hostApi.startMonitoring();

  @override
  Future<void> stopMonitoring() => _hostApi.stopMonitoring();

  @override
  Future<PlatformCallResult> answer() => _hostApi.answer();

  @override
  Future<PlatformCallResult> end() => _hostApi.end();

  @override
  Future<PlatformCallResult> silenceRinger() => _hostApi.silenceRinger();

  @override
  Future<PlatformCallResult> dial(String number) => _hostApi.dial(number);

  @override
  Future<List<PlatformCallLogEntry>> recentCalls(int limit) =>
      _hostApi.recentCalls(limit);

  @override
  Future<PlatformContact?> lookupContact(String number) =>
      _hostApi.lookupContact(number);
}

class _EventRelay implements CallsFlutterApi {
  _EventRelay(this._sink);

  final StreamController<PlatformPhoneEvent> _sink;

  @override
  void onPhoneEvent(PlatformPhoneEvent event) => _sink.add(event);
}
