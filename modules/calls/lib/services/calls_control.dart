import 'package:calls/models/models.dart';

/// What a computer can see and do with calls on connected phones. The
/// feature implements it; view models and notices depend on this, so tests
/// can drive them by hand.
abstract interface class CallsControl {
  /// The calls ringing or going on, on every connected phone.
  List<RemoteCall> get remoteCalls;

  /// Fires when [remoteCalls], a phone's status or a setting changes.
  Stream<void> get changes;

  /// Every change of a call, the last one with the ended state.
  Stream<RemoteCall> get callEvents;

  /// Whether to show a notice when a phone rings.
  bool get showIncoming;

  Future<CommandOutcome> answer(RemoteCall call);

  /// Declines [call] while it rings, hangs it up otherwise.
  Future<CommandOutcome> end(RemoteCall call);

  Future<CommandOutcome> silence(RemoteCall call);

  /// Calls [number] from the phone [deviceId].
  Future<CommandOutcome> dial(String deviceId, String number);

  Future<CallLogResult> fetchCallLog(String deviceId, {int limit});
}
