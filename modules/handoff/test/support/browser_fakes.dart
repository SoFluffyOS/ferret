import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';

const chromeOrigin = 'chrome-extension://abcdefghijklmnopabcdefghijklmnop';
const firefoxOrigin = 'moz-extension://0d6f3c1e-8a2b-4c5d-9e7f-1a2b3c4d5e6f';

/// One extension connection, driven by the test.
class FakeChannel implements BrowserChannel {
  FakeChannel({this.origin = chromeOrigin});

  @override
  final String origin;

  final StreamController<String> _incoming = .new();
  final List<Map<String, Object?>> sent = [];
  int? closedWith;

  @override
  Stream<String> get messages => _incoming.stream;

  /// The extension sends [message].
  void say(Map<String, Object?> message) => _incoming.add(jsonEncode(message));

  void sayRaw(String text) => _incoming.add(text);

  /// The extension went away.
  Future<void> disconnect() => _incoming.close();

  List<Map<String, Object?>> ofType(String type) => [
    for (final message in sent)
      if (message['type'] == type) message,
  ];

  Map<String, Object?> last(String type) => ofType(type).last;

  @override
  void send(Map<String, Object?> message) => sent.add(message);

  @override
  Future<void> close([int code = 1001, String reason = '']) async {
    closedWith = code;
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}

/// A Handoff feature whose sends and publishes are recorded instead of
/// going to devices.
class RecordingFeature extends HandoffFeature {
  RecordingFeature({super.opener});

  final List<(String, Activity)> sends = [];
  final List<Activity> published = [];
  SendOutcome outcome = .opened;

  @override
  Future<SendOutcome> sendTo(String deviceId, Activity activity) async {
    sends.add((deviceId, activity));
    return outcome;
  }

  @override
  Future<int> publish(Activity activity) async {
    published.add(activity);
    return 1;
  }
}

/// A server that never binds, for bridges tested through fake channels.
class IdleServer extends BrowserBridgeServer {
  IdleServer({this.port = BrowserBridgeServer.firstPort});

  @override
  final int? port;

  bool started = false;

  @override
  Future<int?> start(void Function(BrowserChannel channel) onChannel) async {
    started = true;
    return port;
  }

  @override
  Future<void> stop() async => started = false;
}

TrustedDevice trustedDevice(String id, String name) => TrustedDevice(
  id: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
);
