import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter/foundation.dart';
import 'package:updates/models/models.dart';
import 'package:updates/services/services.dart';

/// The update check and install: asks for the newest release once a day
/// (or on Check now), then, only when the person taps Install, downloads
/// it, checks it against the release's SHA256SUMS, lets the platform's
/// installer check the signature and install it, and quits to restart.
class UpdatesViewModel extends ChangeNotifier {
  UpdatesViewModel({
    required this.platform,
    required this.currentVersion,
    required UpdateSettings Function() settings,
    required Future<void> Function() quit,
    Future<Directory> Function()? downloads,
    DateTime Function()? clock,
  }) : _settings = settings,
       _quit = quit,
       _downloads = downloads ?? _downloadFolder,
       _clock = clock ?? DateTime.now;

  /// How often the check runs by itself.
  static const interval = Duration(days: 1);

  /// How long a check that ran by itself and failed waits before the next
  /// one. Behind a proxy that blocks GitHub, every try fails, and an hourly
  /// knock would fill the proxy's log for nothing.
  static const retryAfterFailure = Duration(hours: 6);

  /// When a check that ran by itself last failed. Kept in memory: a restart
  /// tries once more.
  DateTime? _failedByItselfAt;

  final UpdatePlatform platform;

  /// This build's version, such as `0.1.0`.
  final String currentVersion;

  final UpdateSettings Function() _settings;
  final Future<void> Function() _quit;
  final Future<Directory> Function() _downloads;
  final DateTime Function() _clock;

  UpdatePhase _phase = .idle;
  UpdatePhase get phase => _phase;

  UpdateProblem? _problem;
  UpdateProblem? get problem => _problem;

  UpdateRelease? _release;

  /// The newer release, once a check found one.
  UpdateRelease? get release => _release;

  double? _progress;

  /// The download's share done, 0 to 1, or null while the size is unknown.
  double? get progress => _progress;

  File? _verified;
  Completer<void>? _cancel;
  bool _disposed = false;

  InstallKind get kind => platform.kind;

  /// Whether this device checks for updates at all.
  bool get isOffered => kind.checks;

  bool get checks => _settings().checks;

  bool get betas => _settings().betas;

  /// Whether there is an update line to show: a newer release the person
  /// hasn't put off, or an install in progress or stopped.
  bool get showsLine {
    final release = _release;
    if (!isOffered || release == null) {
      return false;
    }

    return switch (_phase) {
      .idle || .checking || .upToDate => false,
      .available => _settings().dismissed != release.tag,
      .failed => _problem != .checkFailed,
      _ => true,
    };
  }

  /// Whether the line shows the screen's one filled button: Install, Try
  /// again, Open settings, or Download page where Ferret can't install.
  bool get holdsPrimary => switch (_phase) {
    .available => kind != .packageManager,
    .failed => _problem?.canRetry ?? false,
    .needsPermission => true,
    _ => false,
  };

  /// Checks when the last answer is a day old, the check is on, and Ferret
  /// isn't paused: a pause keeps Ferret off the network, GitHub included.
  Future<void> checkIfDue({required bool paused}) async {
    if (!isOffered || !platform.checksByItself || !checks || paused) {
      return;
    }

    if (_settings().lastCheck case final last?
        when _clock().difference(last) < interval) {
      return;
    }

    if (_failedByItselfAt case final failed?
        when _clock().difference(failed) < retryAfterFailure) {
      return;
    }

    await check(manual: false);
  }

  /// Asks for the newest release. A check the person started shows when
  /// it fails, and brings back a line they put off; one that ran by itself
  /// stays quiet.
  Future<void> check({bool manual = true}) async {
    if (!isOffered || _phase.isBusy) {
      return;
    }

    final before = (_phase, _problem);
    _set(.checking);
    try {
      final newest = await platform.source.newest(
        includePreReleases: betas,
      );
      if (_disposed) {
        return;
      }

      await _settings().setLastCheck(_clock());
      if (newest == null || !isNewerVersion(newest.tag, currentVersion)) {
        _release = null;
        _set(.upToDate);
        return;
      }

      if (manual) {
        await _settings().setDismissed(null);
      }

      _release = newest;
      _set(.available);
    } on Object catch (error) {
      printWarning('Update check failed', error.runtimeType);
      if (_disposed) {
        return;
      }

      if (manual) {
        _set(.failed, problem: .checkFailed);
        return;
      }

      _failedByItselfAt = _clock();
      _set(before.$1, problem: before.$2);
    }
  }

  /// Downloads, checks and installs the release, after the person asked.
  Future<void> install() async {
    final release = _release;
    final installer = platform.installer;
    if (release == null || installer == null || _phase.isBusy) {
      return;
    }

    if (_verified case final file?
        when _phase == .needsPermission || _phase == .handedToSystem) {
      await _hand(installer, file);
      return;
    }

    final asset = platform.target?.assetIn(release);
    if (asset == null) {
      _set(.failed, problem: .noFile);
      return;
    }

    final cancel = Completer<void>();
    _cancel = cancel;
    _progress = 0;
    _set(.downloading);
    File? file;
    try {
      final expected = await _expectedChecksum(release, asset);
      final folder = await _downloads();
      final download = File('${folder.path}/${asset.name}');
      file = download;
      if (await download.exists()) {
        await download.delete();
      }

      await _http.download(
        asset.downloadUrl,
        download,
        expectedSize: asset.size,
        cancelled: cancel.future,
        onProgress: (value) {
          _progress = value;
          _publish();
        },
      );
      if (_disposed) {
        return;
      }

      _set(.verifying);
      final actual = await Checksums.sha256Of(download.path);
      if (actual != expected) {
        throw UpdateRefused(.checksumMismatch, '$actual != $expected');
      }

      await _hand(installer, download);
    } on UpdateDownloadCancelled {
      await _forget(file);
      _set(.available);
    } on UpdateRefused catch (refused) {
      printWarning('Update refused', refused.reason.name);
      await _forget(file);
      _set(.failed, problem: UpdateProblem.refused(refused.reason));
    } on Object catch (error) {
      printWarning('Update failed', error.runtimeType);
      await _forget(file);
      _set(
        .failed,
        problem: switch (_phase) {
          .downloading => .downloadFailed,
          _ => .installFailed,
        },
      );
    } finally {
      _cancel = null;
    }
  }

  /// Stops the download.
  void cancel() {
    if (_cancel case final cancel? when !cancel.isCompleted) {
      cancel.complete();
    }
  }

  /// Puts off this release's line until a newer one, or a Check now.
  Future<void> dismiss() async {
    if (_release case final release?) {
      await _settings().setDismissed(release.tag);
    }

    _verified = null;
    if (_phase == .failed || _phase == .openedForYou) {
      _set(.available);
      return;
    }

    _publish();
  }

  Future<void> setChecks(bool value) async {
    await _settings().setChecks(value);
    _publish();
  }

  Future<void> setBetas(bool value) async {
    await _settings().setBetas(value);
    _publish();
  }

  /// Opens Android's "Install unknown apps" switch for Ferret.
  Future<void> allowInstalls() async {
    if (platform.installer case final AndroidUpdateInstaller android) {
      await android.openPermissionSettings();
    }
  }

  /// Back from Android's settings: goes on with the checked file once
  /// Ferret may install it.
  Future<void> onResumed() async {
    if (_phase != .needsPermission) {
      return;
    }

    if (platform.installer case final AndroidUpdateInstaller android
        when await android.canInstall()) {
      await install();
    }
  }

  /// The release page, for a download by hand.
  Uri get downloadPage =>
      _release?.pageUrl ??
      Uri.https(
        'github.com',
        '/${GithubReleaseSource.defaultRepository}/releases/latest',
      );

  Future<String> _expectedChecksum(
    UpdateRelease release,
    UpdateAsset asset,
  ) async {
    final list = release.assetNamed(UpdateTarget.checksumsName);
    if (list == null) {
      throw const UpdateRefused(.checksumMissing, 'No SHA256SUMS');
    }

    final text = await _http.getText(list.downloadUrl);
    final expected = Checksums.parse(text ?? '')[asset.name];
    if (expected == null) {
      throw UpdateRefused(.checksumMissing, 'No line for ${asset.name}');
    }

    return expected;
  }

  Future<void> _hand(UpdateInstaller installer, File file) async {
    _set(.installing);
    final outcome = await installer.install(file);
    if (_disposed) {
      return;
    }

    switch (outcome) {
      case .quitToRestart:
        _set(.restarting);
        await _quit();
      case .openedForYou:
        _set(.openedForYou);
      case .handedToSystem:
        _verified = file;
        _set(.handedToSystem);
      case .needsPermission:
        _verified = file;
        _set(.needsPermission);
    }
  }

  UpdateHttp get _http => platform.http ?? UpdateHttp();

  Future<void> _forget(File? file) async {
    _verified = null;
    try {
      await file?.delete();
    } on FileSystemException {
      // Never written, or already gone.
    }
  }

  void _set(UpdatePhase phase, {UpdateProblem? problem}) {
    _phase = phase;
    _problem = problem;
    _publish();
  }

  void _publish() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }

  static Future<Directory> _downloadFolder() =>
      Directory('${Directory.systemTemp.path}/ferret-update').create(
        recursive: true,
      );
}
