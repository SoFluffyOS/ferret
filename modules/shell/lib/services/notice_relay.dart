import 'dart:isolate';
import 'dart:ui';

import 'package:core/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Carries a tap on a notice button from the isolate the system starts for
/// it to the app's own one, where the features listen.
///
/// On iPhone a button that doesn't open the app runs [relayNoticeResponse]
/// in an isolate of its own. Ferret's isolate is still alive then (it is
/// only suspended), so the tap is sent there. When Ferret isn't running
/// the tap is dropped with a log line: whatever the notice asked about
/// ended with the app.
///
/// Android delivers such taps to the running app itself, without a second
/// isolate (see the receiver in `ferret_system`).
class NoticeRelay {
  NoticeRelay._(this._port);

  static const portName = 'io.sofluffy.ferret.notice_responses';

  final ReceivePort _port;

  /// Starts taking relayed taps in this isolate and hands each one to
  /// [onResponse]. The newest listener wins.
  static NoticeRelay listen(void Function(NotificationResponse) onResponse) {
    final port = ReceivePort('notice responses');
    IsolateNameServer.removePortNameMapping(portName);
    IsolateNameServer.registerPortWithName(port.sendPort, portName);
    port.listen((message) {
      final response = decode(message);
      if (response != null) {
        onResponse(response);
      }
    });

    return NoticeRelay._(port);
  }

  /// Sends [response] to the listening isolate. False when none listens.
  static bool send(NotificationResponse response) {
    final port = IsolateNameServer.lookupPortByName(portName);
    if (port == null) {
      return false;
    }

    port.send(encode(response));
    return true;
  }

  void close() {
    IsolateNameServer.removePortNameMapping(portName);
    _port.close();
  }

  /// Only plain values cross between isolates started by different engines.
  static List<Object?> encode(NotificationResponse response) => [
    response.id,
    response.actionId,
    response.input,
    response.payload,
    response.notificationResponseType.index,
  ];

  static NotificationResponse? decode(Object? message) {
    if (message
        case [
          final int? id,
          final String? actionId,
          final String? input,
          final String? payload,
          final int type,
        ]
        when type >= 0 && type < NotificationResponseType.values.length) {
      return NotificationResponse(
        id: id,
        actionId: actionId,
        input: input,
        payload: payload,
        notificationResponseType: NotificationResponseType.values[type],
      );
    }

    return null;
  }
}

/// Where the system sends a button tap that doesn't open the app.
@pragma('vm:entry-point')
void relayNoticeResponse(NotificationResponse response) {
  if (NoticeRelay.send(response)) {
    return;
  }

  printWarning(
    'Ferret is not running; dropped the tap on ${response.actionId} '
    'of notice ${response.payload}',
  );
}
