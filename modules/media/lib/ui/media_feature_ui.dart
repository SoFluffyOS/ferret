import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_media/ferret_media.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/feature/feature.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/ui/frames/frames.dart';
import 'package:media/ui/media_activity.dart';
import 'package:media/ui/media_health.dart';
import 'package:media/ui/pages/now_playing_page.dart';
import 'package:media/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The app side of Media: the "now playing" line in Activity and its
/// settings.
class MediaFeatureUi extends FeatureUi {
  MediaFeatureUi({MediaFeature? feature, MediaPlatform? platform})
    : _platform = platform ?? _currentPlatform(),
      feature = feature ?? _platformFeature(platform ?? _currentPlatform());

  @override
  final MediaFeature feature;

  final MediaPlatform _platform;
  MediaViewModel? _viewModel;
  AppLifecycleListener? _lifecycle;

  @override
  String get featureId => MediaFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MediaLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.mediaL10n.title;

  @override
  IconData get icon => LucideIcons.music;

  MediaViewModel get viewModel =>
      _viewModel ??= MediaViewModel(feature, platform: _platform);

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    _lifecycle ??= AppLifecycleListener(
      onResume: () => viewModel.refreshAccess(),
    );
  }

  @override
  Listenable get uiChanges => viewModel;

  /// Never: what plays on another device is a line in Activity.
  @override
  bool hasHomeCard(FeatureContext feature) => false;

  /// One pinned line while something plays, or is paused, on another device.
  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      MediaActivity.items(
        context.mediaL10n,
        viewModel,
        onTap: () => unawaited(
          feature.push<void>(NowPlayingPage(viewModel: viewModel)),
        ),
      );

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    return mediaHealthOf(
      platformMediaL10n(),
      session: session,
      name: device.device.name,
      model: viewModel,
    );
  }

  @override
  SettingsGroup get settingsGroup => .continueAndMedia;

  @override
  Widget buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MediaSettingsFrame(),
      );

  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.mediaL10n;

    return [
      FeatureSettings(
        group: settingsGroup,
        title: l10n.title,
        child: buildSettings(context, feature),
        summary: mediaSummaryOf(l10n, viewModel),
        isOn: viewModel.showRemote || viewModel.isSharing,
        needsAttention: viewModel.lostAccess,
      ),
    ];
  }

  static MediaFeature _platformFeature(MediaPlatform platform) =>
      switch (platform) {
        .ios || .other => MediaFeature(),
        .macos => MediaFeature(
          backend: FerretMedia.platform,
          shareByDefault: false,
        ),
        _ => MediaFeature(backend: FerretMedia.platform),
      };

  static MediaPlatform _currentPlatform() {
    if (Platform.isAndroid) {
      return .android;
    }

    if (Platform.isIOS) {
      return .ios;
    }

    if (Platform.isMacOS) {
      return .macos;
    }

    if (Platform.isWindows) {
      return .windows;
    }

    if (Platform.isLinux) {
      return .linux;
    }

    return .other;
  }
}
