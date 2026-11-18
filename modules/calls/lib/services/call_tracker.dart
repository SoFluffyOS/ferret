import 'dart:math';

import 'package:ferret_calls/ferret_calls.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/calls.dart';

/// Turns the phone's coarse call state (idle, ringing, off hook) into calls
/// with an id, a direction and a life: ringing, then active, then ended.
///
/// Android tells apps neither when an outgoing call is picked up nor which
/// call is on hold, so outgoing calls stay "dialing" and a call waiting that
/// stops ringing ends without an outcome.
class CallTracker {
  CallTracker({DateTime Function()? clock, String Function()? newId})
    : _clock = clock ?? DateTime.now,
      _newId = newId ?? _randomId;

  /// How long a number dialed through Ferret is expected to show up as an
  /// outgoing call.
  static const dialWindow = Duration(seconds: 20);

  final DateTime Function() _clock;
  final String Function() _newId;
  final Set<String> _declined = {};

  Call? _primary;
  Call? _waiting;
  String? _expectedNumber;
  DateTime? _expectedAt;

  /// The calls going on, the first one first.
  List<Call> get calls => [
    for (final call in [_primary, _waiting])
      if (call != null) call.deepCopy(),
  ];

  bool get hasCalls => _primary != null;

  Call? find(String id) {
    for (final call in [_primary, _waiting]) {
      if (call != null && call.id == id) {
        return call.deepCopy();
      }
    }

    return null;
  }

  /// The call that is ringing now, if any.
  Call? get ringing {
    for (final call in [_waiting, _primary]) {
      if (call != null && call.state == CallState.CALL_STATE_RINGING) {
        return call.deepCopy();
      }
    }

    return null;
  }

  /// Ferret is about to call [number], so the next outgoing call is to it.
  void expectOutgoing(String number) {
    _expectedNumber = number;
    _expectedAt = _clock();
  }

  /// Someone declined the ringing call [id] through Ferret, so its end is
  /// not a missed call. [declined] false takes it back.
  void markDeclined(String id, {bool declined = true}) {
    if (declined) {
      _declined.add(id);
      return;
    }

    _declined.remove(id);
  }

  /// Adds the contact's [name] and [photo] to call [id]. Returns the call to
  /// publish, or null when it is gone or nothing changed.
  Call? setContact(String id, {required String name, List<int>? photo}) {
    for (final call in [_primary, _waiting]) {
      if (call == null || call.id != id) {
        continue;
      }

      if (call.contactName == name && photo == null) {
        return null;
      }

      call.contactName = name;
      if (photo != null) {
        call.photoJpeg = photo;
      }

      return call.deepCopy();
    }

    return null;
  }

  /// Takes a change of the phone's state and returns the calls that changed,
  /// in the order to publish them.
  List<Call> handle(PlatformPhoneState state, {String? number}) {
    final known = switch (number) {
      final String value when value.trim().isNotEmpty => value.trim(),
      _ => null,
    };

    final changed = switch (state) {
      .idle => _onIdle(),
      .ringing => _onRinging(known),
      .offHook => _onOffHook(known),
    };

    return [for (final call in changed) call.deepCopy()];
  }

  /// Ends every call without an outcome, such as when monitoring stops.
  List<Call> reset() {
    final ended = [
      for (final call in [_waiting, _primary])
        if (call != null)
          (call
                ..state = .CALL_STATE_ENDED
                ..outcome = .CALL_OUTCOME_UNSPECIFIED)
              .deepCopy(),
    ];
    _clear();
    return ended;
  }

  List<Call> _onRinging(String? number) {
    final primary = _primary;
    if (primary == null) {
      final call = _start(
        .CALL_DIRECTION_INCOMING,
        .CALL_STATE_RINGING,
        number,
      );
      _primary = call;
      return [call];
    }

    if (primary.state == CallState.CALL_STATE_RINGING) {
      return _learnNumber(primary, number);
    }

    final waiting = _waiting;
    if (waiting == null) {
      final call = _start(
        .CALL_DIRECTION_INCOMING,
        .CALL_STATE_RINGING,
        number,
      );
      _waiting = call;
      return [call];
    }

    return _learnNumber(waiting, number);
  }

  List<Call> _onOffHook(String? number) {
    final primary = _primary;
    if (primary == null) {
      final call = _start(
        .CALL_DIRECTION_OUTGOING,
        .CALL_STATE_DIALING,
        number ?? _takeExpectedNumber(),
      );
      _primary = call;
      return [call];
    }

    final waiting = _waiting;
    if (waiting != null) {
      _waiting = null;
      waiting
        ..state = .CALL_STATE_ENDED
        ..outcome = switch (_declined.remove(waiting.id)) {
          true => .CALL_OUTCOME_DECLINED,
          false => .CALL_OUTCOME_UNSPECIFIED,
        };
      return [waiting];
    }

    if (primary.state == CallState.CALL_STATE_RINGING) {
      primary
        ..state = .CALL_STATE_ACTIVE
        ..connectedAtMs = _now();
      if (number != null && primary.number.isEmpty) {
        primary.number = number;
      }

      return [primary];
    }

    return _learnNumber(primary, number);
  }

  List<Call> _onIdle() {
    final ended = <Call>[];
    for (final call in [_waiting, _primary]) {
      if (call == null) {
        continue;
      }

      call
        ..outcome = _outcomeOf(call)
        ..state = .CALL_STATE_ENDED;
      ended.add(call);
    }

    _clear();
    return ended;
  }

  CallOutcome _outcomeOf(Call call) {
    if (call.state == CallState.CALL_STATE_RINGING) {
      return switch (_declined.contains(call.id)) {
        true => .CALL_OUTCOME_DECLINED,
        false => .CALL_OUTCOME_MISSED,
      };
    }

    return switch (call.direction) {
      .CALL_DIRECTION_INCOMING => .CALL_OUTCOME_ANSWERED,
      _ => .CALL_OUTCOME_UNSPECIFIED,
    };
  }

  List<Call> _learnNumber(Call call, String? number) {
    if (number == null || call.number.isNotEmpty) {
      return const [];
    }

    call.number = number;
    return [call];
  }

  Call _start(CallDirection direction, CallState state, String? number) => Call(
    id: _newId(),
    number: number ?? '',
    direction: direction,
    state: state,
    startedAtMs: _now(),
  );

  String? _takeExpectedNumber() {
    final number = _expectedNumber;
    final expectedAt = _expectedAt;
    _expectedNumber = null;
    _expectedAt = null;
    if (number == null || expectedAt == null) {
      return null;
    }

    if (_clock().difference(expectedAt) > dialWindow) {
      return null;
    }

    return number;
  }

  void _clear() {
    _primary = null;
    _waiting = null;
    _declined.clear();
  }

  Int64 _now() => Int64(_clock().millisecondsSinceEpoch);

  static String _randomId() {
    final random = Random.secure();
    return [
      for (var index = 0; index < 8; index++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
