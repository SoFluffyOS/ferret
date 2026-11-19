import 'dart:async';
import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/clipboard.dart';
import 'package:protocol/protocol.dart';

/// A clipboard in memory that records writes and lets tests fire changes.
class FakeClipboard implements ClipboardPlatform {
  FakeClipboard({this.access = .always, this.content});

  @override
  final ClipboardAccess access;

  ClipboardContent? content;
  final List<ClipboardContent> writes = [];
  final StreamController<void> _changes = .broadcast();
  bool watching = false;
  bool failWrites = false;

  /// Someone copied [copied] in another app.
  void copy(ClipboardContent copied) {
    content = copied;
    _changes.add(null);
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<ClipboardContent?> read() async => content;

  @override
  Future<void> write(ClipboardContent written) async {
    if (failWrites) {
      throw StateError('write failed');
    }

    writes.add(written);
    content = written;
    _changes.add(null);
  }

  @override
  Future<void> startWatching() async => watching = true;

  @override
  Future<void> stopWatching() async => watching = false;
}

/// A connected device that records what it was sent.
class FakeSession implements Session {
  FakeSession(
    this.remoteDeviceId, {
    this.name = 'Pixel',
    this.flags = const ['receive', 'send', 'images'],
  });

  @override
  final String remoteDeviceId;
  final String name;
  final List<String> flags;
  final List<ClipPush> pushes = [];
  bool failSends = false;

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: remoteDeviceId, name: name);

  @override
  bool supports(String featureId) => featureId == ClipboardFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) => switch (supports(
    featureId,
  )) {
    true => FeatureSupport(id: featureId, flags: flags),
    false => null,
  };

  @override
  Future<void> send(String feature, GeneratedMessage message) async {
    if (failSends) {
      throw StateError('send failed');
    }

    if (message case final ClipPush push) {
      pushes.add(push);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Just enough of the engine for the feature: settings and sessions.
class FakeHost implements FeatureHost {
  FakeHost(this.identity, {Map<String, Object?>? settings})
    : settings = MemorySettingsStore(settings);

  static Future<FakeHost> create({Map<String, Object?>? settings}) async =>
      FakeHost(await DeviceIdentity.generate(), settings: settings);

  @override
  final DeviceIdentity identity;

  @override
  final MemorySettingsStore settings;

  @override
  final TrustStore trustStore = TrustStore.memory();

  @override
  List<Session> sessions = [];

  @override
  Session? sessionFor(String deviceId) {
    for (final session in sessions) {
      if (session.remoteDeviceId == deviceId) {
        return session;
      }
    }

    return null;
  }

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [push] as it arrives in an envelope.
Envelope envelopeOf(ClipPush push) => Envelope(
  id: Int64(1),
  feature: ClipboardFeature.featureId,
  type: push.payloadType,
  payload: push.toPayload(),
);

/// A clip copied on another device.
ClipPush pushOf(
  String text, {
  String id = 'remote-1',
  String source = 'pixelpixelpixelp',
  bool sensitive = false,
}) => ClipPush(
  item: ClipItem(
    id: id,
    kind: .CLIP_KIND_TEXT,
    text: text,
    sourceDeviceId: source,
    sensitive: sensitive,
    createdAtMs: Int64(DateTime.now().millisecondsSinceEpoch),
  ),
  expiresInMs: Int64(120000),
);

/// Lets queued stream events and futures run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

/// Pairs [deviceId] in [store] and names it [nickname] on this device only.
Future<void> nameHere(
  TrustStore store,
  String deviceId,
  String nickname,
) async {
  await store.save(
    TrustedDevice(
      id: deviceId,
      name: 'Pixel',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026, 11),
    ),
  );
  await store.rename(deviceId, nickname);
}
