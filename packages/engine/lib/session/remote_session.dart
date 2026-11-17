import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/session/session_exception.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Feature id of the messages the session itself uses.
const sessionFeature = 'session';

/// A live, trusted connection to one paired device.
class Session {
  Session({
    required this.channel,
    required Stream<List<int>> messages,
    required this.remoteDeviceId,
    required this.initiatedByLocal,
    required this.initiatorDeviceId,
    this.keepAlive = const Duration(seconds: 20),
    this.idleTimeout = const Duration(seconds: 65),
  }) {
    _subscription = messages.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
    );
    _keepAliveTimer = .periodic(keepAlive, (_) => _sendPing());
    _lastReceived = DateTime.now();
  }

  final SecureChannel channel;
  final String remoteDeviceId;

  /// Whether this device opened the connection.
  final bool initiatedByLocal;

  /// The device id of the side that opened the connection, used to keep one
  /// session when both sides connect at the same time.
  final String initiatorDeviceId;

  final Duration keepAlive;
  final Duration idleTimeout;

  final StreamController<Envelope> _incoming = .broadcast(sync: true);
  final Map<int, Completer<Envelope>> _pending = {};
  final Completer<void> _closed = .new();
  late final StreamSubscription<List<int>> _subscription;
  late final Timer _keepAliveTimer;
  late DateTime _lastReceived;
  int _nextId = 1;

  /// What the remote device said about itself, once its `Hello` arrived.
  Hello? remoteHello;

  Presence remotePresence = Presence(batteryPercent: -1);

  /// Envelopes that are not replies to this side's requests.
  Stream<Envelope> get incoming => _incoming.stream;

  /// Completes when the session ends.
  Future<void> get closed => _closed.future;

  bool get isClosed => _closed.isCompleted;

  DeviceInfo? get remoteDevice => remoteHello?.device;

  /// Whether the remote device offers [featureId].
  bool supports(String featureId) =>
      remoteHello?.features.any((feature) => feature.id == featureId) ?? false;

  FeatureSupport? remoteFeature(String featureId) {
    for (final feature in remoteHello?.features ?? const <FeatureSupport>[]) {
      if (feature.id == featureId) {
        return feature;
      }
    }

    return null;
  }

  /// Sends [message] for [feature] without waiting for an answer.
  Future<void> send(String feature, GeneratedMessage message) => _write(
    Envelope(
      id: _takeId(),
      feature: feature,
      type: message.payloadType,
      payload: message.toPayload(),
    ),
  );

  /// Sends [message] and waits for the reply envelope.
  Future<Envelope> request(
    String feature,
    GeneratedMessage message, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final id = _takeId();
    final reply = Completer<Envelope>();
    _pending[id.toInt()] = reply;

    try {
      await _write(
        Envelope(
          id: id,
          feature: feature,
          type: message.payloadType,
          payload: message.toPayload(),
          expectsReply: true,
        ),
      );
      final envelope = await reply.future.timeout(timeout);
      if (envelope.hasError()) {
        throw RemoteErrorException(envelope.error.code, envelope.error.message);
      }

      return envelope;
    } finally {
      _pending.remove(id.toInt());
    }
  }

  /// Sends a request and decodes the reply as [T].
  Future<T> call<T extends GeneratedMessage>(
    String feature,
    GeneratedMessage message,
    T Function() create, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final envelope = await request(feature, message, timeout: timeout);
    final reply = unpackPayload(
      type: envelope.type,
      payload: envelope.payload,
      create: create,
    );
    if (reply == null) {
      throw RemoteErrorException(
        .ERROR_CODE_INVALID,
        'Expected ${create().payloadType}, got ${envelope.type}',
      );
    }

    return reply;
  }

  /// Answers [request] with [message].
  Future<void> reply(Envelope request, GeneratedMessage message) => _write(
    Envelope(
      id: _takeId(),
      replyTo: request.id,
      feature: request.feature,
      type: message.payloadType,
      payload: message.toPayload(),
    ),
  );

  /// Answers [request] with an error.
  Future<void> replyError(
    Envelope request,
    ErrorCode code, [
    String message = '',
  ]) => _write(
    Envelope(
      id: _takeId(),
      replyTo: request.id,
      feature: request.feature,
      error: Error(code: code, message: message),
    ),
  );

  Future<void> sendHello(Hello hello) => send(sessionFeature, hello);

  Future<void> sendPresence(Presence presence) =>
      send(sessionFeature, presence);

  /// Says goodbye with [reason], then closes.
  Future<void> close([GoodbyeReason reason = .GOODBYE_REASON_SHUTDOWN]) async {
    if (isClosed) {
      return;
    }

    try {
      await send(
        sessionFeature,
        Goodbye(reason: reason),
      ).timeout(const Duration(seconds: 2));
    } on Object {
      printDebug('Goodbye to $remoteDeviceId was not sent');
    }

    await _shutDown();
  }

  /// The reason the other side gave when it said goodbye, if it did.
  GoodbyeReason? remoteGoodbye;

  Future<void> _write(Envelope envelope) {
    if (isClosed) {
      return Future.error(const SessionClosedException());
    }

    return channel.send(envelope.writeToBuffer());
  }

  Int64 _takeId() => Int64(_nextId++);

  void _onMessage(List<int> bytes) {
    _lastReceived = DateTime.now();

    final Envelope envelope;
    try {
      envelope = Envelope.fromBuffer(bytes);
    } on Object catch (error) {
      printWarning('Dropped a malformed envelope from $remoteDeviceId', error);
      return;
    }

    if (envelope.replyTo != 0) {
      _pending[envelope.replyTo.toInt()]?.complete(envelope);
      return;
    }

    if (envelope.feature == sessionFeature) {
      _onSessionEnvelope(envelope);
      return;
    }

    _incoming.add(envelope);
  }

  void _onSessionEnvelope(Envelope envelope) {
    if (unpackPayload(
          type: envelope.type,
          payload: envelope.payload,
          create: Ping.new,
        )
        case final ping?) {
      unawaited(
        send(
          sessionFeature,
          Pong(pingSentAtMs: ping.sentAtMs),
        ).catchError((Object _) {}),
      );
      return;
    }

    if (unpackPayload(
          type: envelope.type,
          payload: envelope.payload,
          create: Goodbye.new,
        )
        case final goodbye?) {
      remoteGoodbye = goodbye.reason;
      unawaited(_shutDown());
      return;
    }

    if (unpackPayload(
          type: envelope.type,
          payload: envelope.payload,
          create: Presence.new,
        )
        case final presence?) {
      remotePresence = presence;
    }

    _incoming.add(envelope);
  }

  void _sendPing() {
    if (DateTime.now().difference(_lastReceived) > idleTimeout) {
      printLog('Session with $remoteDeviceId went quiet; closing');
      unawaited(_shutDown());
      return;
    }

    final now = Int64(DateTime.now().millisecondsSinceEpoch);
    unawaited(
      send(sessionFeature, Ping(sentAtMs: now)).catchError((Object _) {}),
    );
  }

  void _onError(Object error) {
    printWarning('Session with $remoteDeviceId failed', error);
    unawaited(_shutDown());
  }

  void _onDone() => unawaited(_shutDown());

  Future<void> _shutDown() async {
    if (isClosed) {
      return;
    }

    _closed.complete();
    _keepAliveTimer.cancel();
    for (final pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(const SessionClosedException());
      }
    }

    _pending.clear();
    await _subscription.cancel();
    await channel.close();
    await _incoming.close();
  }
}
