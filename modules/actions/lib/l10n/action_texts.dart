import 'package:actions/l10n/generated/actions_localizations.dart';
import 'package:actions/models/models.dart';
import 'package:protocol/actions.dart';

/// Actions in words: their names, the question a device asks this
/// computer's owner, and the switch that lets it skip the question.
extension ActionTexts on ActionsLocalizations {
  /// What to call an action of [kind]; a custom one goes by its [title].
  String actionLabel(ActionKind kind, String title) => switch (kind) {
    .ACTION_KIND_SLEEP => actionSleep,
    .ACTION_KIND_RESTART => actionRestart,
    .ACTION_KIND_SHUT_DOWN => actionShutDown,
    .ACTION_KIND_MUTE => actionMute,
    .ACTION_KIND_VOLUME_UP => actionVolumeUp,
    .ACTION_KIND_VOLUME_DOWN => actionVolumeDown,
    _ => title,
  };

  String consentTitleOf(ActionAsk ask, ComputerKind computer) =>
      switch (ask.action.kind) {
        .ACTION_KIND_SLEEP => consentSleep(ask.deviceName, computer.name),
        .ACTION_KIND_RESTART => consentRestart(ask.deviceName, computer.name),
        .ACTION_KIND_SHUT_DOWN => consentShutDown(
          ask.deviceName,
          computer.name,
        ),
        .ACTION_KIND_MUTE ||
        .ACTION_KIND_VOLUME_UP ||
        .ACTION_KIND_VOLUME_DOWN => consentSound(ask.deviceName, computer.name),
        _ => consentCustom(ask.deviceName, ask.action.title, computer.name),
      };

  /// The whole question in one paragraph, for a system notice: with what
  /// a custom action runs, word for word.
  String consentNoticeBodyOf(ActionAsk ask) => [
    if (ask.action.commandLine.isNotEmpty)
      consentCommandNotice(ask.action.commandLine),
    if (ask.action.countsDown) consentCountsDown,
    consentBody(ask.deviceName),
  ].join(' ');

  String countdownTitleOf(
    ActionCountdown countdown,
    ComputerKind computer,
    int seconds,
  ) => switch (countdown.action.kind) {
    .ACTION_KIND_SHUT_DOWN => countdownShutDown(computer.name, seconds),
    _ => countdownRestart(computer.name, seconds),
  };

  String countdownNoticeTitleOf(
    ActionCountdown countdown,
    ComputerKind computer,
  ) => switch (countdown.action.kind) {
    .ACTION_KIND_SHUT_DOWN => countdownNoticeShutDown(
      countdown.deviceName,
      computer.name,
    ),
    _ => countdownNoticeRestart(countdown.deviceName, computer.name),
  };

  String permissionLabelOf(OfferedAction action, ComputerKind computer) =>
      switch (action.kind) {
        .ACTION_KIND_SLEEP => permissionSleep(computer.name),
        .ACTION_KIND_RESTART => permissionRestart(computer.name),
        .ACTION_KIND_SHUT_DOWN => permissionShutDown(computer.name),
        .ACTION_KIND_MUTE ||
        .ACTION_KIND_VOLUME_UP ||
        .ACTION_KIND_VOLUME_DOWN => permissionSound(computer.name),
        _ => permissionCustom(action.title),
      };

  /// How a run on this computer went, for its line in Activity and in the
  /// history. [commandSeconds] is how long a custom action may run.
  String recordDetailOf(ActionRecord record, {required int commandSeconds}) =>
      switch (record.result) {
        .RUN_RESULT_DONE when record.output.isNotEmpty => record.output,
        .RUN_RESULT_DONE => recordDone,
        .RUN_RESULT_DENIED => recordDenied,
        .RUN_RESULT_NOT_ANSWERED => recordNotAnswered,
        .RUN_RESULT_CANCELLED => recordCancelled,
        .RUN_RESULT_TIMED_OUT => recordTimedOut(commandSeconds),
        .RUN_RESULT_FAILED => switch (record.exitCode) {
          final code? => recordExitCode(code),
          null when record.kind == .ACTION_KIND_CUSTOM => recordNotStarted,
          null => recordFailed,
        },
        _ => recordFailed,
      };
}
