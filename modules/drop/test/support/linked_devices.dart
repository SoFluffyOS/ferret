import 'dart:async';

import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// Two [DropFeature]s wired back to back through in-memory sessions, so
/// tests can drop and restore the link at exact points.
class LinkedDevices {
  LinkedDevices._(this.laptop, this.phone);

  final LinkedDevice laptop;
  final LinkedDevice phone;

  /// Called before each envelope is delivered, such as to drop the link
  /// after a number of chunks.
  void Function(String from, GeneratedMessage message)? onDeliver;

  static Future<LinkedDevices> start({
    required ReceiveStoreFactory laptopStore,
    required ReceiveStoreFactory phoneStore,
    int chunkSize = 1024,
    int ackEvery = 4,
    Map<String, Object?> phoneSettings = const {},
    Map<String, Object?> laptopSettings = const {},
    SecretStore? laptopSecrets,
    LocalSendOptions localSend = const LocalSendOptions(),
    QuickShareOptions quickShare = const QuickShareOptions(),
  }) async {
    final laptop = LinkedDevice(
      'laptop-id',
      'Laptop',
      DropFeature(
        store: laptopStore,
        chunkSize: chunkSize,
        ackEvery: ackEvery,
        secrets: laptopSecrets,
        localSendOptions: localSend,
        quickShareOptions: quickShare,
      ),
      MemorySettingsStore({...laptopSettings}),
    );
    final phone = LinkedDevice(
      'phone-id',
      'Phone',
      DropFeature(store: phoneStore, chunkSize: chunkSize, ackEvery: ackEvery),
      MemorySettingsStore({...phoneSettings}),
    );
    final link = LinkedDevices._(laptop, phone);
    laptop.trustStore = await TrustStore.open(MemorySecretStore());
    phone.trustStore = await TrustStore.open(MemorySecretStore());
    await laptop.feature.start(laptop);
    await phone.feature.start(phone);
    link.connect();
    return link;
  }

  /// Opens a fresh pair of sessions, like a reconnect.
  void connect() {
    final toPhone = LinkedSession(this, from: laptop, to: phone);
    final toLaptop = LinkedSession(this, from: phone, to: laptop);
    toPhone.peer = toLaptop;
    toLaptop.peer = toPhone;
    laptop.session = toPhone;
    phone.session = toLaptop;
    laptop.feature.onSessionOpened(toPhone);
    phone.feature.onSessionOpened(toLaptop);
    laptop.announceSessions();
    phone.announceSessions();
  }

  /// Breaks the link without a goodbye, like Wi-Fi going away.
  void drop() {
    final toPhone = laptop.session;
    final toLaptop = phone.session;
    laptop.session = null;
    phone.session = null;
    toPhone?.closedByTest = true;
    toLaptop?.closedByTest = true;
    if (toPhone != null) {
      laptop.feature.onSessionClosed(toPhone);
    }

    if (toLaptop != null) {
      phone.feature.onSessionClosed(toLaptop);
    }

    laptop.announceSessions();
    phone.announceSessions();
  }
}

class LinkedDevice implements FeatureHost {
  LinkedDevice(this.id, this.name, this.feature, this.settings);

  final String id;
  final String name;
  final DropFeature feature;

  @override
  final SettingsStore settings;

  @override
  late final TrustStore trustStore;

  LinkedSession? session;
  final StreamController<List<Session>> _sessionChanges = .broadcast();

  /// The drop flags this device announces in place of its own, such as an
  /// older Ferret's.
  List<String>? announcedFlags;

  @override
  DeviceInfo get localDevice => DeviceInfo(
    id: id,
    name: name,
    platform: .PLATFORM_MACOS,
    formFactor: .FORM_FACTOR_LAPTOP,
  );

  @override
  List<Session> get sessions => [?session];

  @override
  Stream<List<Session>> get sessionChanges => _sessionChanges.stream;

  /// Tells listeners the link opened or broke, as the engine does.
  void announceSessions() => _sessionChanges.add(sessions);

  @override
  Session? sessionFor(String deviceId) => switch (session) {
    final current? when current.remoteDeviceId == deviceId => current,
    _ => null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One side of an in-memory session. Envelopes are delivered in order, each
/// on a later microtask, and handled without waiting like the engine does.
class LinkedSession implements Session {
  LinkedSession(this.link, {required this.from, required this.to});

  final LinkedDevices link;
  final LinkedDevice from;
  final LinkedDevice to;
  late LinkedSession peer;
  bool closedByTest = false;
  final List<GeneratedMessage> sent = [];

  /// Set by a test to stand in for a slow link.
  @override
  bool isWeak = false;

  @override
  String get remoteDeviceId => to.id;

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: to.id, name: to.name);

  @override
  bool get isClosed => closedByTest;

  @override
  bool supports(String featureId) => featureId == DropFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) => FeatureSupport(
    id: DropFeature.featureId,
    flags: to.announcedFlags ?? to.feature.flags,
  );

  @override
  Future<void> send(String feature, GeneratedMessage message) async {
    await _deliver(message, expectsReply: false);
  }

  @override
  Future<Envelope> request(
    String feature,
    GeneratedMessage message, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final reply = await _deliver(message, expectsReply: true);
    if (reply == null) {
      throw const RemoteErrorException(.ERROR_CODE_CANCELLED, '');
    }

    return Envelope(type: reply.payloadType, payload: reply.toPayload());
  }

  @override
  Future<T> call<T extends GeneratedMessage>(
    String feature,
    GeneratedMessage message,
    T Function() create, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final envelope = await request(feature, message, timeout: timeout);
    return create()..mergeFromBuffer(envelope.payload);
  }

  @override
  Future<void> replyError(
    Envelope request,
    ErrorCode code, [
    String message = '',
  ]) async {}

  Future<GeneratedMessage?> _deliver(
    GeneratedMessage message, {
    required bool expectsReply,
  }) async {
    if (closedByTest) {
      throw const SessionClosedException();
    }

    sent.add(message);
    link.onDeliver?.call(from.id, message);
    await Future<void>.delayed(Duration.zero);
    if (closedByTest) {
      throw const SessionClosedException();
    }

    final envelope = Envelope(
      feature: DropFeature.featureId,
      type: message.payloadType,
      payload: message.toPayload(),
      expectsReply: expectsReply,
    );
    final handled = to.feature.onEnvelope(peer, envelope);
    if (!expectsReply) {
      unawaited(handled.then((_) {}, onError: (Object _) {}));
      return null;
    }

    final reply = await handled;
    if (closedByTest) {
      throw const SessionClosedException();
    }

    return reply;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
