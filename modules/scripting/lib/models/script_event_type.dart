/// The `type` of each [ScriptEvent]. They are part of the documented
/// schema: never rename one.
abstract final class ScriptEventType {
  /// First line of every `watch`: the paired devices right now, under
  /// `devices`.
  static const ready = 'ready';

  static const deviceConnected = 'device.connected';
  static const deviceDisconnected = 'device.disconnected';

  /// The connection dropped and Ferret is dialing the device again.
  static const deviceReconnecting = 'device.reconnecting';

  /// `percent` changed (0-100).
  static const battery = 'battery';

  /// `kind` is `text` or `image`. `text` only with `--include-content`.
  static const clipboardReceived = 'clipboard.received';

  /// `files`, `bytes`; `paths` when previews show.
  static const fileReceived = 'file.received';

  /// `app`; `title` when previews show; `text` with `--include-content`.
  static const notificationReceived = 'notification.received';

  /// A call on the phone rings here. `caller` when previews show.
  static const callRinging = 'call.ringing';

  /// `missed` says whether nobody answered.
  static const callEnded = 'call.ended';

  /// `id`, `direction`, `bytes`, `total`; at most about once a second.
  static const transferProgress = 'transfer.progress';

  /// `id`, `direction`, `result` (`done`, `failed`, `cancelled`), `files`.
  static const transferDone = 'transfer.done';

  /// Another device ran an action on this computer: `action`, `result`.
  static const actionRun = 'action.run';

  static const all = [
    ready,
    deviceConnected,
    deviceDisconnected,
    deviceReconnecting,
    battery,
    clipboardReceived,
    fileReceived,
    notificationReceived,
    callRinging,
    callEnded,
    transferProgress,
    transferDone,
    actionRun,
  ];
}
