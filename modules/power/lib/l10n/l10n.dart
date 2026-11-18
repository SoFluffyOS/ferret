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
    .notifications => perkNotifications,
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
    .grantFailed => noticeGrantFailed,
    .rootRefused => noticeRootRefused,
    .settingsNotOpened => noticeSettingsNotOpened,
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

  String rootFoundText(RootManager manager) => switch (manager) {
    .magisk => rootFoundWith('Magisk'),
    .kernelSu => rootFoundWith('KernelSU'),
    .aPatch => rootFoundWith('APatch'),
    .none || .unknown => rootFound,
  };
}
