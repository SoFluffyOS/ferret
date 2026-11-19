import 'package:protocol/actions.dart';

/// One time a device ran, or tried to run, an action on this computer.
class ActionRecord {
  const ActionRecord({
    required this.deviceId,
    required this.deviceName,
    required this.actionId,
    required this.kind,
    required this.at,
    required this.result,
    this.title = '',
    this.exitCode,
    this.output = '',
  });

  final String deviceId;
  final String deviceName;
  final String actionId;
  final ActionKind kind;

  /// A custom action's name, or empty.
  final String title;
  final DateTime at;
  final RunResult result;
  final int? exitCode;

  /// The last line a custom action printed. Kept in memory only: it is
  /// never stored and never sent.
  final String output;

  /// Unique among the records, for Activity.
  String get id => '$deviceId.$actionId.${at.microsecondsSinceEpoch}';

  static ActionRecord? fromJson(Object? json) {
    if (json case {
      'device': final String deviceId,
      'name': final String deviceName,
      'action': final String actionId,
      'kind': final int kind,
      'at': final int at,
      'result': final int result,
    }) {
      return ActionRecord(
        deviceId: deviceId,
        deviceName: deviceName,
        actionId: actionId,
        kind: ActionKind.valueOf(kind) ?? .ACTION_KIND_UNSPECIFIED,
        at: DateTime.fromMillisecondsSinceEpoch(at),
        result: RunResult.valueOf(result) ?? .RUN_RESULT_UNSPECIFIED,
        title: switch (json['title']) {
          final String title => title,
          _ => '',
        },
        exitCode: switch (json['exit_code']) {
          final int exitCode => exitCode,
          _ => null,
        },
      );
    }

    return null;
  }

  Map<String, Object?> toJson() => {
    'device': deviceId,
    'name': deviceName,
    'action': actionId,
    'kind': kind.value,
    'at': at.millisecondsSinceEpoch,
    'result': result.value,
    if (title.isNotEmpty) 'title': title,
    'exit_code': ?exitCode,
  };
}
