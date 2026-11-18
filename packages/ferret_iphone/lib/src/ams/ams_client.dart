import 'dart:async';
import 'dart:convert';

import 'package:ferret_iphone/src/ams/ams_commands.dart';
import 'package:ferret_iphone/src/ams/ams_ids.dart';
import 'package:ferret_iphone/src/ams/ams_state.dart';
import 'package:ferret_iphone/src/ams/ams_update.dart';
import 'package:ferret_iphone/src/transport/transport.dart';

/// Apple Media Service over an [AppleTransport]: follows what the iPhone
/// plays and sends it play, pause, next, previous and volume.
class AmsClient {
  AmsClient(this._transport, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppleTransport _transport;
  final DateTime Function() _clock;
  final StreamController<AmsState> _states = .broadcast(sync: true);

  StreamSubscription<GattValue>? _subscription;
  AmsState _state = const AmsState();
  Future<void> _fullReads = Future.value();

  AmsState get state => _state;

  /// Fires with the new [state] on every change.
  Stream<AmsState> get states => _states.stream;

  /// Subscribes to the player, the queue and the track. Throws
  /// [GattException] when the iPhone refuses, such as when it isn't bonded.
  Future<void> start() async {
    _subscription ??= _transport.values.listen(_onValue);
    await _transport.setNotify(.remoteCommand, enabled: true);
    await _transport.setNotify(.entityUpdate, enabled: true);
    await _transport.write(
      .entityUpdate,
      AmsCommands.subscribe(.player, AmsPlayerAttribute.all),
    );
    await _transport.write(
      .entityUpdate,
      AmsCommands.subscribe(.queue, AmsQueueAttribute.all),
    );
    await _transport.write(
      .entityUpdate,
      AmsCommands.subscribe(.track, AmsTrackAttribute.all),
    );
  }

  /// Stops listening and forgets what was playing.
  void stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _set(const AmsState());
  }

  void dispose() {
    stop();
    unawaited(_states.close());
  }

  /// Tells the iPhone's player to do [command].
  Future<void> send(AmsCommand command) =>
      _transport.write(.remoteCommand, AmsCommands.remote(command));

  void _onValue(GattValue value) {
    if (value.characteristic == .remoteCommand) {
      _set(_state.withSupported(AmsCommands.supported(value.bytes)));
      return;
    }

    if (value.characteristic != .entityUpdate) {
      return;
    }

    final update = AmsUpdate.parse(value.bytes);
    if (update == null) {
      return;
    }

    _set(_state.apply(update, _clock()));
    if (update.isTruncated) {
      _fullReads = _fullReads.then((_) => _readFull(update));
    }
  }

  /// A long title arrives cut short; the whole text is read separately.
  Future<void> _readFull(AmsUpdate update) async {
    try {
      await _transport.write(
        .entityAttribute,
        AmsCommands.select(update.entity, update.attribute),
      );
      final bytes = await _transport.read(.entityAttribute);
      if (_subscription == null) {
        return;
      }

      final full = AmsUpdate(
        entity: update.entity,
        attribute: update.attribute,
        value: utf8.decode(bytes, allowMalformed: true),
      );
      _set(_state.apply(full, _clock()));
    } on GattException {
      // The cut-short text is still shown.
    }
  }

  void _set(AmsState state) {
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
    }
  }
}
