import 'dart:io';

import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Records commands and answers them like the real tools would.
class _FakeTools {
  _FakeTools({
    this.codesignVerify = 0,
    this.codesignDetails =
        'Identifier=io.sofluffy.ferret\n'
        'Authority=Developer ID Application: Cuong Pham (66UZUS2MST)\n'
        'TeamIdentifier=66UZUS2MST\n',
    this.spctl = 'accepted\nsource=Notarized Developer ID\n',
    this.spctlExit = 0,
    this.signatures = const {},
  });

  final int codesignVerify;
  final String codesignDetails;
  final String spctl;
  final int spctlExit;

  /// Windows: `Status|Subject` by file path.
  final Map<String, String> signatures;

  final runs = <List<String>>[];
  final detached = <List<String>>[];

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    runs.add([executable, ...arguments]);
    switch ((executable, arguments.firstOrNull)) {
      case ('hdiutil', 'attach'):
        final mount = arguments[arguments.indexOf('-mountpoint') + 1];
        Directory(p.join(mount, 'Ferret.app', 'Contents'))
            .createSync(recursive: true);
        return ProcessResult(1, 0, '', '');
      case ('ditto', _):
        Directory(p.join(arguments[1], 'Contents')).createSync(recursive: true);
        return ProcessResult(1, 0, '', '');
      case ('codesign', '--verify'):
        return ProcessResult(1, codesignVerify, '', 'invalid signature');
      case ('codesign', '-dv'):
        return ProcessResult(1, 0, '', codesignDetails);
      case ('spctl', _):
        return ProcessResult(1, spctlExit, '', spctl);
      case ('powershell.exe', _):
        final path = environment?['FERRET_SIGNED_FILE'] ?? '';
        return ProcessResult(1, 0, signatures[path] ?? 'NotSigned|', '');
    }

    return ProcessResult(1, 0, '', '');
  }

  Future<void> detach(String executable, List<String> arguments) async {
    detached.add([executable, ...arguments]);
  }
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('installers');
  });

  tearDown(() => root.delete(recursive: true));

  group('Mac', () {
    late String app;
    late File dmg;

    setUp(() {
      app = p.join(root.path, 'Applications', 'Ferret.app');
      Directory(p.join(app, 'Contents', 'MacOS')).createSync(recursive: true);
      File(p.join(app, 'Contents', 'MacOS', 'ferret')).writeAsStringSync('old');
      dmg = File(p.join(root.path, 'Ferret-mac.dmg'))..writeAsStringSync('dmg');
    });

    MacUpdateInstaller installer(
      _FakeTools tools, {
      bool writable = true,
    }) => MacUpdateInstaller(
      executable: p.join(app, 'Contents', 'MacOS', 'ferret'),
      processId: 42,
      run: tools.run,
      detached: tools.detach,
      scratch: () => Directory(p.join(root.path, 'mnt')).create(),
      canWrite: (_) async => writable,
    );

    test('checks the app, swaps it in and reopens after quitting', () async {
      final tools = _FakeTools();

      final outcome = await installer(tools).install(dmg);

      expect(outcome, InstallOutcome.quitToRestart);
      expect(
        File(p.join(app, 'Contents', 'MacOS', 'ferret')).existsSync(),
        isFalse,
      );
      expect(Directory(p.join(app, 'Contents')).existsSync(), isTrue);
      expect(
        Directory(p.join(root.path, 'Applications', '.Ferret-old-42.app'))
            .existsSync(),
        isTrue,
      );
      final verifies = tools.runs.where(
        (run) => run.first == 'codesign' && run[1] == '--verify',
      );
      expect(verifies.map((run) => run.last), [
        p.join(root.path, 'mnt', 'Ferret.app'),
        p.join(root.path, 'Applications', '.Ferret-update-42.app'),
      ]);
      expect(
        tools.runs.where((run) => run.first == 'spctl'),
        hasLength(2),
      );
      final relaunch = tools.detached.single;
      expect(relaunch.first, '/bin/sh');
      expect(relaunch.sublist(4), [
        '42',
        app,
        p.join(root.path, 'Applications', '.Ferret-old-42.app'),
      ]);
      expect(tools.runs.last.take(2), ['hdiutil', 'detach']);
    });

    Future<void> expectRefused(_FakeTools tools, RefusalReason reason) async {
      await expectLater(
        installer(tools).install(dmg),
        throwsA(
          isA<UpdateRefused>().having(
            (refused) => refused.reason,
            'reason',
            reason,
          ),
        ),
      );
      expect(
        File(p.join(app, 'Contents', 'MacOS', 'ferret')).readAsStringSync(),
        'old',
      );
      expect(tools.detached, isEmpty);
      expect(tools.runs.where((run) => run.first == 'ditto'), isEmpty);
      expect(tools.runs.last.take(2), ['hdiutil', 'detach']);
    }

    test('refuses a broken signature', () async {
      await expectRefused(_FakeTools(codesignVerify: 1), .notSigned);
    });

    test('refuses another team', () async {
      await expectRefused(
        _FakeTools(
          codesignDetails:
              'Identifier=io.sofluffy.ferret\n'
              'Authority=Developer ID Application: Someone (ABCDE12345)\n'
              'TeamIdentifier=ABCDE12345\n',
        ),
        .wrongPublisher,
      );
    });

    test('refuses another app signed by the team', () async {
      await expectRefused(
        _FakeTools(
          codesignDetails:
              'Identifier=io.sofluffy.other\n'
              'Authority=Developer ID Application: Cuong Pham (66UZUS2MST)\n'
              'TeamIdentifier=66UZUS2MST\n',
        ),
        .wrongPublisher,
      );
    });

    test(
      'refuses an app Gatekeeper rejects or that is not notarized',
      () async {
        await expectRefused(
          _FakeTools(spctlExit: 3, spctl: 'rejected'),
          .notNotarized,
        );
        await expectRefused(
          _FakeTools(spctl: 'accepted\nsource=Developer ID\n'),
          .notNotarized,
        );
      },
    );

    test('without write access, opens the checked DMG for a drag', () async {
      final tools = _FakeTools();

      final outcome = await installer(tools, writable: false).install(dmg);

      expect(outcome, InstallOutcome.openedForYou);
      expect(tools.runs, contains(equals(['open', dmg.path])));
      expect(tools.runs.where((run) => run.first == 'ditto'), isEmpty);
      expect(tools.detached, isEmpty);
      expect(
        File(p.join(app, 'Contents', 'MacOS', 'ferret')).readAsStringSync(),
        'old',
      );
    });
  });

  group('Windows', () {
    const exe = r'C:\Ferret\ferret.exe';
    late File setup;

    setUp(() {
      setup = File(p.join(root.path, 'Ferret-windows-x64-setup.exe'))
        ..writeAsStringSync('setup');
    });

    WindowsUpdateInstaller installer(_FakeTools tools) =>
        WindowsUpdateInstaller(
          executable: exe,
          processId: 7,
          run: tools.run,
          detached: tools.detach,
        );

    Future<void> expectRefused(_FakeTools tools, RefusalReason reason) async {
      await expectLater(
        installer(tools).install(setup),
        throwsA(
          isA<UpdateRefused>().having(
            (refused) => refused.reason,
            'reason',
            reason,
          ),
        ),
      );
      expect(tools.detached, isEmpty);
    }

    test('runs the setup silently when both share a publisher', () async {
      final tools = _FakeTools(
        signatures: {
          exe: 'Valid|CN=SoFluffy, O=SoFluffy',
          setup.path: 'Valid|CN=SoFluffy, O=SoFluffy',
        },
      );

      final outcome = await installer(tools).install(setup);

      expect(outcome, InstallOutcome.quitToRestart);
      final launch = tools.detached.single;
      expect(launch.first, 'powershell.exe');
      final script = File(launch.last).readAsStringSync();
      expect(script, contains('Get-Process -Id 7'));
      expect(script, contains("'/VERYSILENT'"));
      expect(script, contains("'/MERGETASKS=!firewall'"));
      expect(script, contains("Start-Process -FilePath '$exe'"));
    });

    test('refuses an unsigned setup', () async {
      await expectRefused(
        _FakeTools(signatures: {exe: 'Valid|CN=SoFluffy'}),
        .notSigned,
      );
      await expectRefused(
        _FakeTools(
          signatures: {exe: 'Valid|CN=SoFluffy', setup.path: 'HashMismatch|'},
        ),
        .notSigned,
      );
    });

    test('refuses another publisher', () async {
      await expectRefused(
        _FakeTools(
          signatures: {
            exe: 'Valid|CN=SoFluffy',
            setup.path: 'Valid|CN=Someone Else',
          },
        ),
        .wrongPublisher,
      );
    });

    test('refuses when this copy is unsigned', () async {
      await expectRefused(
        _FakeTools(signatures: {setup.path: 'Valid|CN=SoFluffy'}),
        .unsignedHere,
      );
    });

    test('quotes paths for PowerShell', () {
      final script = WindowsUpdateInstaller.updateScript(
        processId: 1,
        setupPath: r"C:\Users\O'Neil\setup.exe",
        appPath: r'C:\Ferret\ferret.exe',
        logPath: r'C:\log.txt',
      );

      expect(script, contains(r"'C:\Users\O''Neil\setup.exe'"));
    });
  });

  group('Linux AppImage', () {
    test('renames the new AppImage over the old one, then reopens', () async {
      final appImage = File(p.join(root.path, 'Ferret.AppImage'))
        ..writeAsStringSync('old');
      final download = File(p.join(root.path, 'download.AppImage'))
        ..writeAsStringSync('new');
      final tools = _FakeTools();

      final outcome = await LinuxUpdateInstaller(
        appImage: appImage.path,
        processId: 9,
        run: tools.run,
        detached: tools.detach,
      ).install(download);

      expect(outcome, InstallOutcome.quitToRestart);
      expect(appImage.readAsStringSync(), 'new');
      expect(tools.runs.single, [
        'chmod',
        '755',
        p.join(root.path, '.Ferret.AppImage.update-9'),
      ]);
      expect(tools.detached.single.sublist(4), ['9', appImage.path]);
    });
  });
}
