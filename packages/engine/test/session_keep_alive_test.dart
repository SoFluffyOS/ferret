import 'dart:async';

import 'package:engine/engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  test('two sessions ping at most half as often as before and stay up, '
      'with a round trip timed on both sides', () {
    fakeAsync((async) {
      final link = _Link();
      final laptop = link.session('phone', initiatedByLocal: true);
      final phone = link.session('laptop', initiatedByLocal: false);
      async.elapse(const Duration(minutes: 10));

      // Before, each side pinged every 20 s: 60 pings in 10 minutes.
      expect(link.pings, lessThanOrEqualTo(30));
      expect(link.pings, greaterThanOrEqualTo(10));
      expect(laptop.isClosed, isFalse);
      expect(phone.isClosed, isFalse);
      expect(laptop.roundTrip, isNotNull);
      expect(phone.roundTrip, isNotNull);
      for (final session in [laptop, phone]) {
        unawaited(session.close());
      }
      async.flushMicrotasks();
    });
  });

  test('next to an older device that pings every 20 s, this side pings '
      'only to time the round trip', () {
    fakeAsync((async) {
      final link = _Link(oldAnswers: true);
      final session = link.session('old-phone', initiatedByLocal: true);
      async.elapse(const Duration(seconds: 7));
      link.fromOld(_ping());
      final old = Timer.periodic(
        const Duration(seconds: 20),
        (_) => link.fromOld(_ping()),
      );
      async.elapse(const Duration(minutes: 10));

      expect(link.sentByFirst.where(_isPing).length, lessThanOrEqualTo(7));
      expect(session.isClosed, isFalse);
      old.cancel();
      unawaited(session.close());
      async.flushMicrotasks();
    });
  });

  test('a device that goes silent is still dropped after the idle timeout', () {
    fakeAsync((async) {
      final link = _Link();
      final session = link.session('gone', initiatedByLocal: true);
      async.elapse(const Duration(seconds: 59));
      expect(session.isClosed, isFalse);
      async.elapse(const Duration(seconds: 30));
      expect(session.isClosed, isTrue);
    });
  });
}

var _ids = 1000;

Envelope _ping() => Envelope(
  id: Int64(_ids++),
  feature: sessionFeature,
  type: Ping().payloadType,
  payload: Ping().toPayload(),
);

bool _isPing(List<int> bytes) {
  final envelope = Envelope.fromBuffer(bytes);
  return envelope.feature == sessionFeature &&
      envelope.type == Ping().payloadType;
}

/// Two sessions wired to each other through fake channels, or one session
/// next to a peer that only exists as the messages fed to it.
class _Link {
  _Link({this.oldAnswers = false});

  /// Whether a lone session's peer answers its pings.
  final bool oldAnswers;
  final _toFirst = StreamController<List<int>>.broadcast(sync: true);
  final _toSecond = StreamController<List<int>>.broadcast(sync: true);
  final sentByFirst = <List<int>>[];
  final sentBySecond = <List<int>>[];
  var _made = 0;

  int get pings =>
      sentByFirst.where(_isPing).length + sentBySecond.where(_isPing).length;

  Session session(String remote, {required bool initiatedByLocal}) {
    final first = _made++ == 0;
    final channel = _FakeChannel((bytes) {
      // Hand off a moment later, like a real network.
      final copy = List<int>.of(bytes);
      if (first) {
        sentByFirst.add(copy);
        Timer(const Duration(milliseconds: 5), () => _toSecond.add(copy));
        if (oldAnswers && _made == 1) {
          _answerAsOld(copy);
        }
      } else {
        sentBySecond.add(copy);
        Timer(const Duration(milliseconds: 5), () => _toFirst.add(copy));
      }
    });
    return Session(
      channel: channel,
      messages: first ? _toFirst.stream : _toSecond.stream,
      remoteDeviceId: remote,
      initiatedByLocal: initiatedByLocal,
      initiatorDeviceId: initiatedByLocal ? 'me' : remote,
    );
  }

  /// The older device answers pings, as every version does.
  void _answerAsOld(List<int> bytes) {
    final envelope = Envelope.fromBuffer(bytes);
    if (!_isPing(bytes)) {
      return;
    }

    final ping = Ping.fromBuffer(envelope.payload);
    final pong = Pong(pingSentAtMs: ping.sentAtMs);
    Timer(
      const Duration(milliseconds: 5),
      () => fromOld(
        Envelope(
          id: Int64(_ids++),
          feature: sessionFeature,
          type: pong.payloadType,
          payload: pong.toPayload(),
        ),
      ),
    );
  }

  void fromOld(Envelope envelope) => _toFirst.add(envelope.writeToBuffer());
}

class _FakeChannel implements SecureChannel {
  _FakeChannel(this._onSend);

  final void Function(List<int> bytes) _onSend;

  @override
  Future<void> send(List<int> message) async => _onSend(message);

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
