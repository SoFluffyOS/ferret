import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/notice_relay.dart';

void main() {
  tearDown(() => IsolateNameServer.removePortNameMapping(NoticeRelay.portName));

  const tap = NotificationResponse(
    id: 42,
    actionId: 'mirroring.deny',
    input: 'On my way',
    payload: 'mirroring.request',
    notificationResponseType:
        NotificationResponseType.selectedNotificationAction,
  );

  test('a response survives the trip between isolates', () {
    final back = NoticeRelay.decode(NoticeRelay.encode(tap))!;

    expect(back.id, 42);
    expect(back.actionId, 'mirroring.deny');
    expect(back.input, 'On my way');
    expect(back.payload, 'mirroring.request');
    expect(
      back.notificationResponseType,
      NotificationResponseType.selectedNotificationAction,
    );
  });

  test('anything else is not a response', () {
    expect(NoticeRelay.decode('mirroring.deny'), isNull);
    expect(NoticeRelay.decode([1, 'a', null, 'p', 99]), isNull);
  });

  test('the background entry point hands the tap to the app', () async {
    final received = Completer<NotificationResponse>();
    final relay = NoticeRelay.listen(received.complete);
    addTearDown(relay.close);

    relayNoticeResponse(tap);

    final response = await received.future.timeout(const Duration(seconds: 5));
    expect(response.actionId, 'mirroring.deny');
    expect(response.payload, 'mirroring.request');
  });

  test('a tap from another isolate reaches the app', () async {
    final received = Completer<NotificationResponse>();
    final relay = NoticeRelay.listen(received.complete);
    addTearDown(relay.close);
    final sendPort = IsolateNameServer.lookupPortByName(NoticeRelay.portName)!;

    await Isolate.run(() => sendPort.send(NoticeRelay.encode(tap)));

    final response = await received.future.timeout(const Duration(seconds: 5));
    expect(response.input, 'On my way');
  });

  test('with no app listening the tap is dropped', () {
    expect(NoticeRelay.send(tap), isFalse);
    expect(() => relayNoticeResponse(tap), returnsNormally);
  });
}
