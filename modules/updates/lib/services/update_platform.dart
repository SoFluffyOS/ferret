import 'dart:io';

import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter/foundation.dart';

/// What updating means on this device: how Ferret was installed, which
/// file it wants, where releases come from and what installs them.
class UpdatePlatform {
  const UpdatePlatform({
    required this.kind,
    required this.target,
    required this.source,
    required this.http,
    this.installer,
    this.checksByItself = true,
  });

  /// Nothing at all, as on an iPhone.
  static const none = UpdatePlatform(
    kind: .store,
    target: null,
    source: _NoReleases(),
    http: null,
  );

  final InstallKind kind;
  final UpdateTarget? target;
  final ReleaseSource source;
  final UpdateHttp? http;

  /// Null where Ferret doesn't install updates itself.
  final UpdateInstaller? installer;

  /// Whether the daily check runs by itself: in release builds, and in any
  /// build pointed at a test feed. Check now works everywhere.
  final bool checksByItself;

  /// This device's. FERRET_UPDATE_FEED points it at a test feed instead of
  /// GitHub.
  static Future<UpdatePlatform> detect() async {
    final feed = FeedReleaseSource.fromEnvironment();
    final target = UpdateTarget.current;
    if (target == null) {
      return none;
    }

    final kind = await InstallKind.detect(
      operatingSystem: Platform.operatingSystem,
      executable: Platform.resolvedExecutable,
      environment: Platform.environment,
      isReleaseBuild: kReleaseMode || feed != null,
      androidInstaller: switch (Platform.isAndroid) {
        true => await AndroidUpdateInstaller.installerPackage(),
        false => null,
      },
    );
    final http = UpdateHttp(allowInsecure: feed != null);
    return UpdatePlatform(
      kind: kind,
      target: target,
      source: feed ?? GithubReleaseSource(http: http),
      http: http,
      installer: _installerFor(kind),
      checksByItself: kReleaseMode || feed != null,
    );
  }

  static UpdateInstaller? _installerFor(InstallKind kind) => switch (kind) {
    .macApp => MacUpdateInstaller(),
    .windowsSetup => WindowsUpdateInstaller(),
    .linuxAppImage => LinuxUpdateInstaller(
      appImage: Platform.environment['APPIMAGE'] ?? '',
    ),
    .androidApk => const AndroidUpdateInstaller(),
    .packageManager || .manual || .store => null,
  };
}

class _NoReleases implements ReleaseSource {
  const _NoReleases();

  @override
  Future<UpdateRelease?> newest({required bool includePreReleases}) async =>
      null;
}
