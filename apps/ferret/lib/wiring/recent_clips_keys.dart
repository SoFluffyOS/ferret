import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:shell/shell.dart';

/// The keys that open Recent clips from any app, as set in Settings →
/// Advanced, for the Recent clips page. The shell owns them and Clipboard
/// never imports the shell, so the app passes them along.
abstract final class RecentClipsKeys {
  /// "⌃⌥V" until the person picks others; null when they are off, or off
  /// a Mac, where Ferret has no such keys.
  static String? of(FeatureContext feature) {
    if (!Platform.isMacOS) {
      return null;
    }

    return GlobalShortcut.read(
      feature.engine.settings,
      key: GlobalShortcut.clipsKey,
      fallback: GlobalShortcut.recentClips,
    )?.label;
  }
}
