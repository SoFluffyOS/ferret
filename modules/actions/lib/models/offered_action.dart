import 'package:actions/models/action_ids.dart';
import 'package:protocol/actions.dart';

/// One action this computer offers its paired devices.
class OfferedAction {
  const OfferedAction({
    required this.id,
    required this.kind,
    this.title = '',
    this.commandLine = '',
  });

  final String id;
  final ActionKind kind;

  /// The owner's name for a custom action, or empty.
  final String title;

  /// What a custom action runs, or empty. Never sent to another device.
  final String commandLine;

  /// The computer is out of reach once it ran, so the answer goes out
  /// first.
  bool get leavesReach => switch (kind) {
    .ACTION_KIND_SLEEP ||
    .ACTION_KIND_RESTART ||
    .ACTION_KIND_SHUT_DOWN => true,
    _ => false,
  };

  /// Closes what is open here: the owner gets a countdown to cancel it,
  /// and the asking device confirms first.
  bool get countsDown => switch (kind) {
    .ACTION_KIND_RESTART || .ACTION_KIND_SHUT_DOWN => true,
    _ => false,
  };

  /// What "Always allow" is remembered under: the three sound actions
  /// share one answer.
  String get grantId => switch (kind) {
    .ACTION_KIND_MUTE ||
    .ACTION_KIND_VOLUME_UP ||
    .ACTION_KIND_VOLUME_DOWN => ActionIds.soundGrant,
    _ => id,
  };

  /// As other devices get it: without the command line.
  Action toProto() =>
      Action(id: id, kind: kind, title: title, confirm: countsDown);
}
