import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_iphone/src/ancs/ancs_attribute.dart';
import 'package:ferret_iphone/src/ancs/ancs_commands.dart';
import 'package:ferret_iphone/src/ancs/ancs_event.dart';
import 'package:ferret_iphone/src/ancs/ancs_notification.dart';
import 'package:ferret_iphone/src/ancs/ancs_response.dart';
import 'package:ferret_iphone/src/transport/transport.dart';

/// Apple Notification Center Service over an [AppleTransport]: tells about
/// notifications as they come and go, fetches their text and the app's name,
/// and performs their actions.
class AncsClient {
  AncsClient(
    this._transport, {
    this.requestTimeout = const Duration(seconds: 5),
    this.maxTextLength = 256,
  });

  static const _attributes = [
    AncsAttribute.appIdentifier,
    AncsAttribute.title,
    AncsAttribute.subtitle,
    AncsAttribute.message,
    AncsAttribute.date,
    AncsAttribute.positiveActionLabel,
    AncsAttribute.negativeActionLabel,
  ];

  /// How long the iPhone gets to answer a command.
  final Duration requestTimeout;

  /// Titles and messages are cut to this many bytes.
  final int maxTextLength;

  final AppleTransport _transport;
  final StreamController<AncsEvent> _events = .broadcast(sync: true);
  final Map<String, String> _appNames = {};

  StreamSubscription<GattValue>? _subscription;
  _PendingAnswer? _pending;
  Future<void> _queue = Future.value();

  /// Every Notification Source packet, including the ones for notifications
  /// that were already there ([AncsEvent.isPreExisting]).
  Stream<AncsEvent> get events => _events.stream;

  /// Subscribes to the iPhone's notifications. Data Source goes first so no
  /// answer is missed. Throws [GattException] when the iPhone refuses, such
  /// as when it isn't bonded.
  Future<void> start() async {
    _subscription ??= _transport.values.listen(_onValue);
    await _transport.setNotify(.dataSource, enabled: true);
    await _transport.setNotify(.notificationSource, enabled: true);
  }

  /// Stops listening and fails the command that waits for an answer.
  void stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _fail(const GattException(.notConnected));
  }

  void dispose() {
    stop();
    unawaited(_events.close());
  }

  /// Fetches the text of the notification [event] is about. Throws
  /// [GattException] when it is already gone or the iPhone doesn't answer.
  Future<AncsNotification> fetch(AncsEvent event) => _enqueue(() async {
    final attributes = await _ask(
      AncsCommands.notificationAttributes(
        event.uid,
        _attributes,
        maxLength: maxTextLength,
      ),
      AncsResponseAssembler.notification(
        event.uid,
        attributeCount: _attributes.length,
      ),
    );

    return AncsNotification.fromAttributes(event, attributes);
  });

  /// The app's name as the iPhone shows it, such as "Messages". Falls back
  /// to [appId] when the iPhone doesn't know it.
  Future<String> appName(String appId) {
    if (appId.isEmpty) {
      return Future.value('');
    }

    if (_appNames[appId] case final known?) {
      return Future.value(known);
    }

    return _enqueue(() async {
      final String name;
      try {
        final attributes = await _ask(
          AncsCommands.appAttributes(appId),
          AncsResponseAssembler.app(appId, attributeCount: 1),
        );
        name = attributes[AncsAppAttribute.displayName] ?? '';
      } on GattException catch (error) {
        if (error.failure == .notConnected) {
          rethrow;
        }

        return appId;
      }

      if (name.isEmpty) {
        return appId;
      }

      _appNames[appId] = name;
      return name;
    });
  }

  /// Asks the iPhone to perform [action] on notification [uid].
  Future<void> perform(int uid, AncsAction action) => _enqueue(
    () => _transport.write(
      .controlPoint,
      AncsCommands.performAction(uid, action),
    ),
  );

  void _onValue(GattValue value) {
    if (value.characteristic == .notificationSource) {
      final event = AncsEvent.parse(value.bytes);
      if (event != null && !_events.isClosed) {
        _events.add(event);
      }

      return;
    }

    if (value.characteristic != .dataSource) {
      return;
    }

    final pending = _pending;
    if (pending == null) {
      return;
    }

    final attributes = pending.assembler.add(value.bytes);
    if (attributes == null) {
      return;
    }

    _pending = null;
    pending.completer.complete(attributes);
  }

  /// One command at a time: answers carry no request id, so a second
  /// command before the first answer would mix them up.
  Future<T> _enqueue<T>(Future<T> Function() command) {
    final result = _queue.then((_) => command());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Map<int, String>> _ask(
    Uint8List command,
    AncsResponseAssembler assembler,
  ) async {
    final pending = _PendingAnswer(assembler);
    pending.completer.future.ignore();
    _pending = pending;
    final timer = Timer(requestTimeout, () {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(const GattException(.timeout));
      }
    });
    try {
      await _transport.write(.controlPoint, command);
      return await pending.completer.future;
    } finally {
      timer.cancel();
      if (identical(_pending, pending)) {
        _pending = null;
      }
    }
  }

  void _fail(GattException error) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.completeError(error);
    }
  }
}

class _PendingAnswer {
  _PendingAnswer(this.assembler);

  final AncsResponseAssembler assembler;
  final Completer<Map<int, String>> completer = .new();
}
