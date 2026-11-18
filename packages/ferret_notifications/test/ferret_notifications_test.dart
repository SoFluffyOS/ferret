import 'dart:async';

import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('platform events arrive on the stream', () async {
    final notifications = FerretNotifications();
    final events = <NotificationEvent>[];
    final subscription = notifications.events.listen(events.add);

    await _sendFromPlatform('onRemoved', ['some-key']);
    await _sendFromPlatform('onListenerChanged', [true]);

    expect(events, hasLength(2));
    expect((events.first as NotificationRemovedEvent).key, 'some-key');
    expect((events.last as ListenerChangedEvent).connected, isTrue);
    await subscription.cancel();
  });

  test('the listener class name matches the Android service', () {
    expect(
      FerretNotifications.listenerClassName,
      'io.sofluffy.ferret_notifications.FerretNotificationListener',
    );
  });
}

Future<void> _sendFromPlatform(String method, List<Object?> arguments) async {
  final channel =
      'dev.flutter.pigeon.ferret_notifications.NotificationsFlutterApi.$method';
  const codec = NotificationsFlutterApi.pigeonChannelCodec;
  final completer = Completer<void>();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        channel,
        codec.encodeMessage(arguments),
        (_) => completer.complete(),
      );
  await completer.future;
}
