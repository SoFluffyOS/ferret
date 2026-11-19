import 'dart:async';

import 'package:actions/actions.dart';
import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:notifications/notifications.dart';
import 'package:scripting/scripting.dart';
import 'package:shell/shell.dart';

/// Turns what the features do into [ScriptEvent]s for `ferret-cli watch`
/// and hook scripts. Features never import each other, so the app joins
/// them here.
///
/// Names that may be private (a notification's title, a caller, a received
/// file's path) are left out while previews from that device are off on
/// this computer, and content (copied text, notification text) also when
/// the item is marked private.
class ScriptEvents {
  ScriptEvents(this._engine, this._hub, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FerretEngine _engine;
  final ScriptEventHub _hub;
  final DateTime Function() _clock;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<String, StreamSubscription<Object?>> _presence = {};
  final Map<String, _Link> _links = {};
  final Map<String, int> _battery = {};
  final Set<String> _seenClips = {};
  final Set<String> _seenNotifications = {};
  final Set<String> _ringing = {};
  final Set<String> _finishedTransfers = {};
  final Map<String, DateTime> _lastProgress = {};
  final Set<ActionRecord> _seenActions = Set.identity();

  static const _progressEvery = Duration(seconds: 1);

  /// Starts reporting to [hub] on this computer.
  static ScriptEvents? attach(FerretEngine engine) {
    final scripting = engine.feature<ScriptingFeature>();
    if (scripting == null) {
      return null;
    }

    return ScriptEvents(engine, scripting.events)..start();
  }

  /// The paired devices right now, as the first line of a `watch` lists
  /// them.
  List<Map<String, Object?>> devices() => [
    for (final status in _engine.devices)
      {
        'id': status.device.id,
        'name': _engine.displayNameOf(status.device.id),
        'connected': status.isConnected,
        if (status.isReconnecting) 'reconnecting': true,
        'battery': ?_battery[status.device.id],
      },
  ];

  void start() {
    for (final status in _engine.devices) {
      _links[status.device.id] = _Link.of(status);
    }

    _watchSessions(_engine.sessions);
    _subscriptions
      ..add(_engine.deviceChanges.listen(_onDevices))
      ..add(_engine.sessionChanges.listen(_watchSessions));
    _startClipboard();
    _startDrop();
    _startNotifications();
    _startCalls();
    _startActions();
  }

  Future<void> dispose() async {
    for (final subscription in [..._subscriptions, ..._presence.values]) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    _presence.clear();
  }

  void _onDevices(List<DeviceStatus> devices) {
    for (final status in devices) {
      final deviceId = status.device.id;
      final link = _Link.of(status);
      final previous = _links[deviceId] ?? _Link.offline;
      _links[deviceId] = link;
      if (link == previous) {
        continue;
      }

      final type = switch (link) {
        .connected => ScriptEventType.deviceConnected,
        .reconnecting => ScriptEventType.deviceReconnecting,
        .offline => ScriptEventType.deviceDisconnected,
      };
      _emit(type, deviceId);
    }
  }

  void _watchSessions(List<Session> sessions) {
    final open = {for (final session in sessions) session.remoteDeviceId};
    for (final deviceId in [..._presence.keys]) {
      if (!open.contains(deviceId)) {
        unawaited(_presence.remove(deviceId)?.cancel());
      }
    }

    for (final session in sessions) {
      final deviceId = session.remoteDeviceId;
      if (_presence.containsKey(deviceId)) {
        continue;
      }

      _onPresence(deviceId, session.remotePresence.batteryPercent);
      _presence[deviceId] = session.presenceChanges.listen(
        (presence) => _onPresence(deviceId, presence.batteryPercent),
      );
    }
  }

  void _onPresence(String deviceId, int percent) {
    if (percent < 0 || _battery[deviceId] == percent) {
      return;
    }

    final known = _battery.containsKey(deviceId);
    _battery[deviceId] = percent;
    if (!known) {
      return;
    }

    _emit(ScriptEventType.battery, deviceId, fields: {'percent': percent});
  }

  void _startClipboard() {
    final clipboard = _engine.feature<ClipboardFeature>();
    if (clipboard == null) {
      return;
    }

    _seenClips.addAll([for (final entry in clipboard.history) entry.item.id]);
    _subscriptions.add(
      clipboard.changes.listen((_) {
        for (final entry in clipboard.history) {
          if (entry.direction != .received || !_seenClips.add(entry.item.id)) {
            continue;
          }

          _onClip(entry);
        }
      }),
    );
  }

  void _onClip(ClipEntry entry) {
    final deviceId = entry.deviceIds.firstOrNull;
    final mayShow =
        deviceId != null &&
        _showsPreviewsFrom(deviceId) &&
        entry.hasContent &&
        !entry.isSensitive &&
        !entry.isImage;

    _emit(
      ScriptEventType.clipboardReceived,
      deviceId,
      fields: {
        'kind': switch (entry.isImage) {
          true => 'image',
          false => 'text',
        },
        if (entry.isSensitive) 'sensitive': true,
      },
      content: {if (mayShow) 'text': entry.item.text},
    );
  }

  void _startDrop() {
    final drop = _engine.feature<DropFeature>();
    if (drop == null) {
      return;
    }

    _finishedTransfers.addAll([
      for (final transfer in drop.transfers)
        if (!transfer.status.isActive) transfer.id,
    ]);
    _subscriptions.add(drop.updates.listen(_onTransfer));
  }

  void _onTransfer(Transfer transfer) {
    if (_finishedTransfers.contains(transfer.id)) {
      return;
    }

    final deviceId = switch (transfer.isUnpaired) {
      true => null,
      false => transfer.deviceId,
    };
    final direction = switch (transfer.direction) {
      .incoming => 'incoming',
      .outgoing => 'outgoing',
    };
    if (transfer.status.isActive) {
      _onProgress(transfer, deviceId, direction);
      return;
    }

    _finishedTransfers.add(transfer.id);
    _lastProgress.remove(transfer.id);
    final result = switch (transfer.status) {
      .done => 'done',
      .cancelled => 'cancelled',
      _ => 'failed',
    };
    _emit(
      ScriptEventType.transferDone,
      deviceId,
      fields: {
        'id': transfer.id,
        'direction': direction,
        'result': result,
        'files': transfer.files.length,
        'bytes': transfer.totalBytes,
      },
    );

    final received = transfer.status == .done && !transfer.isOutgoing;
    if (!received || transfer.isText) {
      return;
    }

    final paths = [
      for (final file in transfer.files) ?file.location,
    ];
    _emit(
      ScriptEventType.fileReceived,
      deviceId,
      fields: {'files': transfer.files.length, 'bytes': transfer.totalBytes},
      private: {
        if (_mayName(deviceId) && paths.isNotEmpty) 'paths': paths,
      },
    );
  }

  void _onProgress(Transfer transfer, String? deviceId, String direction) {
    if (transfer.status != .transferring) {
      return;
    }

    final now = _clock();
    final last = _lastProgress[transfer.id];
    if (last != null && now.difference(last) < _progressEvery) {
      return;
    }

    _lastProgress[transfer.id] = now;
    _emit(
      ScriptEventType.transferProgress,
      deviceId,
      fields: {
        'id': transfer.id,
        'direction': direction,
        'bytes': transfer.bytesDone,
        'total': transfer.totalBytes,
      },
    );
  }

  void _startNotifications() {
    final notifications = _engine.feature<NotificationsFeature>();
    if (notifications == null) {
      return;
    }

    _subscriptions.add(
      notifications.mirrorEvents.listen((event) {
        switch (event) {
          case MirrorPosted(:final notification):
            _onNotification(notification);
          case MirrorRemoved(:final deviceId, :final key):
            _seenNotifications.remove('$deviceId/$key');
          case _:
            return;
        }
      }),
    );
  }

  void _onNotification(MirroredNotification notification) {
    final deviceId = notification.deviceId;
    if (!_seenNotifications.add('$deviceId/${notification.key}')) {
      return;
    }

    final mayName = _showsPreviewsFrom(deviceId);
    final mayShowText = mayName && !notification.textHidden;
    _emit(
      ScriptEventType.notificationReceived,
      deviceId,
      fields: {'app': notification.appName},
      private: {if (mayName) 'title': notification.title},
      content: {if (mayShowText) 'text': notification.text},
    );
  }

  void _startCalls() {
    final calls = _engine.feature<CallsFeature>();
    if (calls == null) {
      return;
    }

    _subscriptions.add(calls.callEvents.listen(_onCall));
  }

  void _onCall(RemoteCall remote) {
    final key = '${remote.deviceId}/${remote.call.id}';
    if (remote.isEnded) {
      _ringing.remove(key);
      _emit(
        ScriptEventType.callEnded,
        remote.deviceId,
        fields: {'missed': remote.wasMissed},
      );
      return;
    }

    if (!remote.isRinging || !remote.isIncoming || !_ringing.add(key)) {
      return;
    }

    final caller = switch (remote.call.contactName.isEmpty) {
      true => remote.call.number,
      false => remote.call.contactName,
    };
    _emit(
      ScriptEventType.callRinging,
      remote.deviceId,
      private: {
        if (_showsPreviewsFrom(remote.deviceId) && caller.isNotEmpty)
          'caller': caller,
      },
    );
  }

  void _startActions() {
    final actionsHost = _engine.feature<ActionsFeature>()?.actionsHost;
    if (actionsHost == null) {
      return;
    }

    _seenActions.addAll(actionsHost.recent);
    _subscriptions.add(
      actionsHost.changes.listen((_) {
        for (final record in actionsHost.recent) {
          if (!_seenActions.add(record)) {
            continue;
          }

          _emit(
            ScriptEventType.actionRun,
            record.deviceId,
            fields: {
              'action': record.actionId,
              'result': record.result.name
                  .replaceFirst('RUN_RESULT_', '')
                  .toLowerCase(),
              'exit_code': ?record.exitCode,
            },
          );
        }
      }),
    );
  }

  bool _mayName(String? deviceId) => switch (deviceId) {
    final id? => _showsPreviewsFrom(id),
    null => false,
  };

  bool _showsPreviewsFrom(String deviceId) =>
      PrivatePreviews(_engine.settings).showsFrom(deviceId);

  void _emit(
    String type,
    String? deviceId, {
    Map<String, Object?> fields = const {},
    Map<String, Object?> private = const {},
    Map<String, Object?> content = const {},
  }) {
    _hub.add(
      ScriptEvent(
        type: type,
        at: _clock(),
        deviceId: deviceId,
        deviceName: switch (deviceId) {
          final id? => _engine.displayNameOf(id),
          null => null,
        },
        fields: fields,
        private: private,
        content: content,
      ),
    );
  }
}

enum _Link {
  connected,
  reconnecting,
  offline;

  static _Link of(DeviceStatus status) {
    if (status.isConnected) {
      return connected;
    }

    if (status.isReconnecting) {
      return reconnecting;
    }

    return offline;
  }
}
