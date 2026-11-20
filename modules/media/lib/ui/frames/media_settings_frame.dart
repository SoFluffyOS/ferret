import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_media/ferret_media.dart';
import 'package:flutter/widgets.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/ui/widgets/widgets.dart';
import 'package:media/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Share my media, show remote media, and what this platform allows.
class MediaSettingsFrame extends StatelessWidget {
  const MediaSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final share = context.select<MediaViewModel, bool>(
      (model) => model.shareEnabled,
    );
    final showRemote = context.select<MediaViewModel, bool>(
      (model) => model.showRemote,
    );
    final canShare = context.select<MediaViewModel, bool>(
      (model) => model.canShare,
    );
    final access = context.select<MediaViewModel, MediaAccess?>(
      (model) => model.access,
    );
    final askedAccess = context.select<MediaViewModel, bool>(
      (model) => model.askedAccess,
    );
    final pauseOnCall = context.select<MediaViewModel, bool>(
      (model) => model.pauseOnCall,
    );
    final model = context.read<MediaViewModel>();
    final l10n = context.mediaL10n;
    final limit = _limit(l10n, model.platform);
    final needsAccess = canShare && share && access == .notGranted;

    return GroupedCard(
      children: [
        if (canShare)
          SettingSwitchRow(
            title: l10n.settingsShare,
            body: l10n.settingsShareBody,
            value: share,
            onChanged: model.setShare,
          ),
        if (needsAccess)
          GroupedCell(
            child: _accessPrompt(l10n, model, askedBefore: askedAccess),
          ),
        SettingSwitchRow(
          title: l10n.settingsShowRemote,
          body: l10n.settingsShowRemoteBody,
          value: showRemote,
          onChanged: model.setShowRemote,
        ),
        if (canShare)
          SettingSwitchRow(
            title: l10n.settingsPauseOnCall,
            body: l10n.settingsPauseOnCallBody,
            value: pauseOnCall,
            onChanged: model.setPauseOnCall,
          ),
        if (limit case final limit?)
          GroupedCell(
            child: Text(
              limit,
              style: context.fluffyTheme.typography.caption1.copyWith(
                color: context.palette.mutedText,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _accessPrompt(
    MediaLocalizations l10n,
    MediaViewModel model, {
    required bool askedBefore,
  }) {
    final (text, label, action) = switch ((model.platform, askedBefore)) {
      (.android, _) => (
        l10n.accessAndroid(ThisComputer.handheld),
        l10n.accessOpenSettings,
        model.openAccessSettings,
      ),
      (.macos, false) => (
        l10n.accessMacos,
        l10n.accessAllow,
        model.requestAccess,
      ),
      _ => (
        l10n.accessDenied,
        l10n.accessOpenSettings,
        model.openAccessSettings,
      ),
    };

    return AccessPrompt(
      text: text,
      actionLabel: label,
      onAction: () => action(),
      checkAgainLabel: l10n.accessCheckAgain,
      onCheckAgain: () => model.refreshAccess(),
    );
  }

  static String? _limit(MediaLocalizations l10n, MediaPlatform platform) =>
      switch (platform) {
        .macos => l10n.limitMacos,
        .ios => l10n.limitIos,
        .windows => l10n.limitWindows,
        .linux => l10n.limitLinux,
        .android || .other => null,
      };
}
