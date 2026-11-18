import 'dart:async';

import 'package:ferret_calls/ferret_calls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('platform call events arrive on the stream', () async {
    final calls = FerretCalls();
    final events = <PlatformPhoneEvent>[];
    final subscription = calls.events.listen(events.add);

    await _sendFromPlatform(
      PlatformPhoneEvent(state: .ringing, number: '+15550100'),
    );
    await _sendFromPlatform(PlatformPhoneEvent(state: .idle));

    expect(events, hasLength(2));
    expect(events.first.state, PlatformPhoneState.ringing);
    expect(events.first.number, '+15550100');
    expect(events.last.state, PlatformPhoneState.idle);
    expect(events.last.number, isNull);
    await subscription.cancel();
  });

  test('commands go to the host and bring its answer back', () async {
    final host = _FakeHostApi();
    final calls = FerretCalls(hostApi: host);

    final dialed = await calls.dial('+15550100');
    final answered = await calls.answer();
    final recent = await calls.recentCalls(50);

    expect(dialed, PlatformCallResult.ok);
    expect(answered, PlatformCallResult.permissionMissing);
    expect(host.dialed, ['+15550100']);
    expect(host.askedLimit, 50);
    expect(recent.single.type, PlatformCallLogType.missed);
  });
}

class _FakeHostApi extends CallsHostApi {
  final List<String> dialed = [];
  int? askedLimit;

  @override
  Future<PlatformCallResult> dial(String number) async {
    dialed.add(number);
    return .ok;
  }

  @override
  Future<PlatformCallResult> answer() async => .permissionMissing;

  @override
  Future<List<PlatformCallLogEntry>> recentCalls(int limit) async {
    askedLimit = limit;
    return [
      PlatformCallLogEntry(
        id: '1',
        number: '+15550100',
        name: 'Alex',
        type: .missed,
        dateMs: 1,
        durationSeconds: 0,
      ),
    ];
  }
}

Future<void> _sendFromPlatform(PlatformPhoneEvent event) async {
  const channel =
      'dev.flutter.pigeon.ferret_calls.CallsFlutterApi.onPhoneEvent';
  const codec = CallsFlutterApi.pigeonChannelCodec;
  final completer = Completer<void>();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        channel,
        codec.encodeMessage([event]),
        (_) => completer.complete(),
      );
  await completer.future;
}
