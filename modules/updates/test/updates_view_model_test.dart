import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:updates/updates.dart';

/// Installs nothing; says what it was asked and answers as told.
class _FakeInstaller implements UpdateInstaller {
  _FakeInstaller({this.outcome = .quitToRestart, this.refuse});

  final InstallOutcome outcome;
  final RefusalReason? refuse;
  final installed = <String>[];

  @override
  Future<InstallOutcome> install(File file) async {
    installed.add(file.readAsStringSync());
    if (refuse case final reason?) {
      throw UpdateRefused(reason, 'test');
    }

    return outcome;
  }
}

/// Counts every check, standing in for GitHub.
class _CountingSource implements ReleaseSource {
  _CountingSource(this.inner);

  final ReleaseSource inner;
  var calls = 0;
  Object? fail;

  @override
  Future<UpdateRelease?> newest({required bool includePreReleases}) async {
    calls++;
    if (fail case final error?) {
      throw error;
    }

    return inner.newest(includePreReleases: includePreReleases);
  }
}

void main() {
  late Directory feed;
  late Directory downloads;
  late MemorySettingsStore settings;
  late DateTime now;
  var quits = 0;

  const file = 'Ferret-mac.dmg';
  const payload = 'the new Ferret';

  void writeRelease({
    String tag = 'v0.2.0',
    String? checksum,
    bool withSums = true,
    bool prerelease = false,
  }) {
    File('${feed.path}/release.json').writeAsStringSync(
      jsonEncode({
        'tag_name': tag,
        'body': '## New\n- Faster',
        'prerelease': prerelease,
      }),
    );
    File('${feed.path}/$file').writeAsStringSync(payload);
    final sums = File('${feed.path}/SHA256SUMS');
    if (withSums) {
      final hash = checksum ?? sha256.convert(utf8.encode(payload)).toString();
      sums.writeAsStringSync('$hash  $file\n');
    }
  }

  ({UpdatesViewModel viewModel, _CountingSource source}) make({
    UpdateInstaller? installer,
    InstallKind kind = .macApp,
    String version = '0.1.0',
  }) {
    final source = _CountingSource(FeedReleaseSource(feed.uri));
    final viewModel = UpdatesViewModel(
      platform: UpdatePlatform(
        kind: kind,
        target: .mac,
        source: source,
        http: UpdateHttp(allowInsecure: true),
        installer: installer,
      ),
      currentVersion: version,
      settings: () => UpdateSettings(settings),
      quit: () async => quits++,
      downloads: () async => downloads,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return (viewModel: viewModel, source: source);
  }

  setUp(() async {
    feed = await Directory.systemTemp.createTemp('feed');
    downloads = await Directory.systemTemp.createTemp('downloads');
    settings = MemorySettingsStore();
    now = DateTime(2026, 11, 22, 9);
    quits = 0;
  });

  tearDown(() async {
    await feed.delete(recursive: true);
    await downloads.delete(recursive: true);
  });

  group('check', () {
    test('finds a newer release and shows the card', () async {
      writeRelease();
      final (:viewModel, source: _) = make();

      await viewModel.check();

      expect(viewModel.phase, UpdatePhase.available);
      expect(viewModel.release?.versionText, '0.2.0');
      expect(viewModel.showsLine, isTrue);
      expect(UpdateSettings(settings).lastCheck, now);
    });

    test('the same or an older version is up to date', () async {
      writeRelease(tag: 'v0.1.0');
      final (:viewModel, source: _) = make();

      await viewModel.check();

      expect(viewModel.phase, UpdatePhase.upToDate);
      expect(viewModel.showsLine, isFalse);
    });

    test('betas count only with the switch on', () async {
      writeRelease(tag: 'v0.2.0-beta.1', prerelease: true);
      final (:viewModel, source: _) = make();

      await viewModel.check();
      expect(viewModel.phase, UpdatePhase.upToDate);

      await viewModel.setBetas(true);
      await viewModel.check();
      expect(viewModel.release?.tag, 'v0.2.0-beta.1');
    });

    test('runs by itself once a day, never while paused or off', () async {
      writeRelease();
      final (:viewModel, :source) = make();

      await viewModel.checkIfDue(paused: true);
      expect(source.calls, 0);

      await viewModel.checkIfDue(paused: false);
      expect(source.calls, 1);

      now = now.add(const Duration(hours: 23));
      await viewModel.checkIfDue(paused: false);
      expect(source.calls, 1);

      now = now.add(const Duration(hours: 2));
      await viewModel.setChecks(false);
      await viewModel.checkIfDue(paused: false);
      expect(source.calls, 1);

      await viewModel.setChecks(true);
      await viewModel.checkIfDue(paused: false);
      expect(source.calls, 2);
    });

    test('a failed check by itself stays quiet; Check now says so', () async {
      final (:viewModel, :source) = make();
      source.fail = const SocketException('offline');

      await viewModel.checkIfDue(paused: false);
      expect(viewModel.phase, UpdatePhase.idle);

      await viewModel.check();
      expect(viewModel.phase, UpdatePhase.failed);
      expect(viewModel.problem, UpdateProblem.checkFailed);
      expect(viewModel.showsLine, isFalse);
    });

    test('Later hides the card until Check now', () async {
      writeRelease();
      final (:viewModel, source: _) = make();
      await viewModel.check();

      await viewModel.dismiss();
      expect(viewModel.showsLine, isFalse);

      await viewModel.check(manual: false);
      expect(viewModel.showsLine, isFalse);

      await viewModel.check();
      expect(viewModel.showsLine, isTrue);
    });

    test('a store install never checks', () async {
      writeRelease();
      final (:viewModel, :source) = make(kind: .store);

      await viewModel.check();
      await viewModel.checkIfDue(paused: false);

      expect(source.calls, 0);
      expect(viewModel.isOffered, isFalse);
    });
  });

  group('install', () {
    test('downloads, checks the hash, installs and quits', () async {
      writeRelease();
      final installer = _FakeInstaller();
      final (:viewModel, source: _) = make(installer: installer);
      await viewModel.check();

      await viewModel.install();

      expect(installer.installed, [payload]);
      expect(viewModel.phase, UpdatePhase.restarting);
      expect(quits, 1);
    });

    test('refuses a file whose hash is not in SHA256SUMS', () async {
      writeRelease(checksum: 'a' * 64);
      final installer = _FakeInstaller();
      final (:viewModel, source: _) = make(installer: installer);
      await viewModel.check();

      await viewModel.install();

      expect(installer.installed, isEmpty);
      expect(viewModel.phase, UpdatePhase.failed);
      expect(viewModel.problem, UpdateProblem.checksumMismatch);
      expect(viewModel.showsLine, isTrue);
      expect(File('${downloads.path}/$file').existsSync(), isFalse);
      expect(quits, 0);
    });

    test('refuses a release without SHA256SUMS before downloading', () async {
      writeRelease(withSums: false);
      final installer = _FakeInstaller();
      final (:viewModel, source: _) = make(installer: installer);
      await viewModel.check();

      await viewModel.install();

      expect(installer.installed, isEmpty);
      expect(viewModel.problem, UpdateProblem.checksumMissing);
      expect(File('${downloads.path}/$file').existsSync(), isFalse);
    });

    test('refuses when SHA256SUMS has no line for the file', () async {
      writeRelease();
      File('${feed.path}/SHA256SUMS').writeAsStringSync(
        '${'b' * 64}  Ferret-android.apk\n',
      );
      final (:viewModel, source: _) = make(installer: _FakeInstaller());
      await viewModel.check();

      await viewModel.install();

      expect(viewModel.problem, UpdateProblem.checksumMissing);
    });

    test('a signature the installer refuses is said, never retried', () async {
      writeRelease();
      final (:viewModel, source: _) = make(
        installer: _FakeInstaller(refuse: .notNotarized),
      );
      await viewModel.check();

      await viewModel.install();

      expect(viewModel.phase, UpdatePhase.failed);
      expect(viewModel.problem, UpdateProblem.notNotarized);
      expect(viewModel.problem?.canRetry, isFalse);
      expect(viewModel.holdsPrimary, isFalse);
      expect(quits, 0);
    });

    test('a release without a file for this system says so', () async {
      writeRelease();
      File('${feed.path}/$file').deleteSync();
      final (:viewModel, source: _) = make(installer: _FakeInstaller());
      await viewModel.check();

      await viewModel.install();

      expect(viewModel.problem, UpdateProblem.noFile);
    });

    test('Android asks for the permission, then goes on', () async {
      writeRelease();
      final (:viewModel, source: _) = make(
        installer: _FakeInstaller(outcome: .needsPermission),
      );
      await viewModel.check();

      await viewModel.install();

      expect(viewModel.phase, UpdatePhase.needsPermission);
      expect(viewModel.holdsPrimary, isTrue);
    });

    test('a Mac without write access opens the DMG instead', () async {
      writeRelease();
      final (:viewModel, source: _) = make(
        installer: _FakeInstaller(outcome: .openedForYou),
      );
      await viewModel.check();

      await viewModel.install();

      expect(viewModel.phase, UpdatePhase.openedForYou);
      expect(quits, 0);
    });

    test('nothing installs where Ferret cannot install itself', () async {
      writeRelease();
      final (:viewModel, source: _) = make(kind: .packageManager);
      await viewModel.check();

      await viewModel.install();

      expect(viewModel.phase, UpdatePhase.available);
      expect(viewModel.holdsPrimary, isFalse);
    });
  });
}
