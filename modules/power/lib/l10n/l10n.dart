import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:power/l10n/generated/power_localizations.dart';
import 'package:power/models/models.dart';

export 'package:power/l10n/generated/power_localizations.dart';

extension PowerL10n on BuildContext {
  PowerLocalizations get powerL10n => PowerLocalizations.of(this);
}

extension PowerLabels on PowerLocalizations {
  String rungTitle(LadderRung rung) => switch (rung) {
    .basic => rungBasic,
    .notifications => rungNotifications,
    .messagesAndCalls => rungMessagesAndCalls,
    .shizuku => rungShizuku,
    .root => rungRoot,
  };

  String perkLabel(LadderPerk perk) => switch (perk) {
    .files => perkFiles,
    .clipboardTap => perkClipboardTap,
    .handoff => perkHandoff,
    .media => perkMedia,
    .find => perkFind,
    .notifications => perkNotifications(ThisComputer.handheld),
    .replies => perkReplies,
    .messages => perkMessages,
    .calls => perkCalls,
    .clipboardBackground => perkClipboardBackground,
    .oneTapSetup => perkOneTapSetup,
    .sameAsShizuku => perkSameAsShizuku,
    .survivesRestart => perkSurvivesRestart,
  };

  String noticeText(PowerNotice notice) => switch (notice) {
    .shizukuRefused => noticeShizukuRefused,
    .shizukuNotOpened => noticeShizukuNotOpened,
    .linkFailed => noticeLinkFailed,
    .grantFailed => noticeGrantFailed(ThisComputer.handheld),
    .rootRefused => noticeRootRefused,
    .settingsNotOpened => noticeSettingsNotOpened(ThisComputer.handheld),
  };

  String promptText(PowerPrompt prompt) => switch (prompt) {
    .startShizuku => cardStartShizuku,
    .allowShizuku => cardAllowShizuku,
    .shizukuStopped => cardShizukuStopped,
    .shizukuRevoked => cardShizukuRevoked,
    .useRoot => cardUseRoot,
    .rootLost => cardRootLost,
  };

  String tierSummary(PowerTier tier) => switch (tier) {
    .standard => settingsSummaryStandard,
    .shizuku => settingsSummaryShizuku,
    .root => settingsSummaryRoot,
  };

  /// The active tier in a word or two, for the row in Settings.
  String tierShort(PowerTier tier) => switch (tier) {
    .standard => settingsShortStandard,
    .shizuku => settingsShortShizuku,
    .root => settingsShortRoot,
  };

  String rootFoundText(RootManager manager) => switch (manager) {
    .magisk => rootFoundWith('Magisk', ThisComputer.handheld),
    .kernelSu => rootFoundWith('KernelSU', ThisComputer.handheld),
    .aPatch => rootFoundWith('APatch', ThisComputer.handheld),
    .none || .unknown => rootFound(ThisComputer.handheld),
  };
}
