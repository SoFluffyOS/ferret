import 'dart:io' as io;

import 'package:core/core.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/activity_opener.dart';
import 'package:handoff/services/open_planner.dart';
import 'package:protocol/handoff.dart';
import 'package:protocol/protocol.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens activities with the system: the app's deep link when that app is
/// installed, else the web page, through `url_launcher`.
class PlatformActivityOpener implements ActivityOpener {
  PlatformActivityOpener({
    Platform? platform,
    FerretHandoff? handoff,
    Future<bool> Function(Uri uri, LaunchMode mode)? launch,
    bool Function()? isInForeground,
  }) : platform = platform ?? currentPlatform(),
       _handoff = handoff ?? FerretHandoff(),
       _launch = launch ?? _launchWithSystem,
       _isInForeground = isInForeground ?? _appIsResumed;

  /// This device's platform, which picks the app id to use.
  final Platform platform;
  final FerretHandoff _handoff;
  final Future<bool> Function(Uri uri, LaunchMode mode) _launch;
  final bool Function() _isInForeground;

  @override
  Future<OpenResult> open(Activity activity) async {
    final steps = OpenPlanner.plan(activity, platform);
    if (steps.isEmpty) {
      return .failed;
    }

    if (_needsForeground(steps) && !_isInForeground()) {
      return .deferred;
    }

    for (final step in steps) {
      if (await _run(step)) {
        return .opened;
      }
    }

    return .failed;
  }

  /// Android doesn't let a background app start another app, so opening
  /// waits for a tap on the notice there.
  bool _needsForeground(List<OpenStep> steps) {
    if (platform != .PLATFORM_ANDROID && platform != .PLATFORM_IOS) {
      return false;
    }

    return steps.any((step) => step is! CopyText);
  }

  Future<bool> _run(OpenStep step) async {
    try {
      switch (step) {
        case OpenInApp(:final uri, :final appId):
          return await _handoff.openInApp(uri, appId);
        case OpenLink(:final uri, :final appsOnly):
          final parsed = Uri.tryParse(uri);
          if (parsed == null) {
            return false;
          }

          return await _launch(parsed, switch (appsOnly) {
            true => LaunchMode.externalNonBrowserApplication,
            false => LaunchMode.externalApplication,
          });
        case CopyText(:final text):
          await Clipboard.setData(ClipboardData(text: text));
          return true;
      }
    } on Object catch (error) {
      printDebug(
        'Handoff open step ${step.runtimeType} failed (${error.runtimeType})',
      );
      return false;
    }
  }

  /// The platform this code runs on, as the protocol names it.
  static Platform currentPlatform() {
    if (io.Platform.isAndroid) {
      return .PLATFORM_ANDROID;
    }

    if (io.Platform.isIOS) {
      return .PLATFORM_IOS;
    }

    if (io.Platform.isMacOS) {
      return .PLATFORM_MACOS;
    }

    if (io.Platform.isWindows) {
      return .PLATFORM_WINDOWS;
    }

    if (io.Platform.isLinux) {
      return .PLATFORM_LINUX;
    }

    return .PLATFORM_UNSPECIFIED;
  }

  static Future<bool> _launchWithSystem(Uri uri, LaunchMode mode) =>
      launchUrl(uri, mode: mode);

  static bool _appIsResumed() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
}
