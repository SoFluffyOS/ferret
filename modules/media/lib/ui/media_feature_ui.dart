import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_media/ferret_media.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/feature/feature.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/ui/frames/frames.dart';
import 'package:media/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The app side of Media: the "Now playing" home card and its settings.
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

  /// Only while something plays, or is paused, on another device.
  @override
  bool hasHomeCard(FeatureContext feature) => viewModel.selected != null;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const NowPlayingFrame(),
      );

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MediaSettingsFrame(),
      );

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
