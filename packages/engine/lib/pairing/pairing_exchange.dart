import 'dart:async';

import 'package:async/async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Feature id of pairing messages.
const pairingFeature = 'pairing';

/// The back and forth of one pairing on a fresh channel, before there is a
/// session: sends pairing messages and reads the next one.
class PairingExchange {
  PairingExchange(this.channel) : _queue = StreamQueue(channel.messages);

  final SecureChannel channel;
  final StreamQueue<List<int>> _queue;
  int _nextId = 1;

  /// What arrives after the pairing is over, for the session to read.
  Stream<List<int>> get rest => _queue.rest;

  /// Sends [message], as a pairing message unless [as] names another
  /// feature.
  Future<void> send(
    GeneratedMessage message, {
    Envelope? replyTo,
    bool expectsReply = false,
    String as = pairingFeature,
  }) => channel.send(
    Envelope(
      id: Int64(_nextId++),
      replyTo: replyTo?.id,
      feature: as,
      type: message.payloadType,
      payload: message.toPayload(),
      expectsReply: expectsReply,
    ).writeToBuffer(),
  );

  /// The next envelope. Throws a [TimeoutException] after [timeout] and a
  /// [StateError] when the other side hung up.
  Future<Envelope> next(Duration timeout) async =>
      Envelope.fromBuffer(await _queue.next.timeout(timeout));

  /// The payload of [envelope] as [T], or null when it is something else.
  static T? read<T extends GeneratedMessage>(
    Envelope envelope,
    T Function() create,
  ) {
    if (envelope.feature != pairingFeature) {
      return null;
    }

    return unpackPayload(
      type: envelope.type,
      payload: envelope.payload,
      create: create,
    );
  }

  Future<void> close() => channel.close();
}
