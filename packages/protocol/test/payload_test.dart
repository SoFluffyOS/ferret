import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('a payload unpacks only as the type it names', () {
    final ping = Ping(sentAtMs: .new(42));
    final envelope = Envelope(
      feature: 'session',
      type: ping.payloadType,
      payload: ping.toPayload(),
    );

    expect(envelope.type, 'ferret.v1.Ping');
    expect(
      unpackPayload(
        type: envelope.type,
        payload: envelope.payload,
        create: Ping.new,
      ),
      ping,
    );
    expect(
      unpackPayload(
        type: envelope.type,
        payload: envelope.payload,
        create: Pong.new,
      ),
      isNull,
    );
  });
}
