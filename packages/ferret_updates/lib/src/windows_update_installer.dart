import 'dart:io';

import 'package:ferret_updates/src/update_installer.dart';
import 'package:path/path.dart' as p;

/// Installs a Windows update with the release's setup.
///
/// It first asks Windows for the setup's Authenticode signature
/// (`Get-AuthenticodeSignature`): it must be valid and come from the same
/// publisher as the running ferret.exe. Then a helper waits for Ferret to
/// quit, runs the setup silently (Inno Setup's `/VERYSILENT`, keeping the
/// install folder and the choices made the first time, without asking for
/// the firewall again) and starts Ferret.
class WindowsUpdateInstaller implements UpdateInstaller {
  WindowsUpdateInstaller({
    String? executable,
    int? processId,
    RunProcess? run,
    StartDetached? detached,
  }) : _executable = executable ?? Platform.resolvedExecutable,
       _pid = processId ?? pid,
       _run = run ?? runProcess,
       _detached = detached ?? startDetached;

  /// Inno Setup's switches for an update nobody has to click through.
  static const setupArguments = [
    '/VERYSILENT',
    '/SUPPRESSMSGBOXES',
    '/NORESTART',
    '/SP-',
    '/MERGETASKS=!firewall',
  ];

  static const _signatureScript =
      r'$s = Get-AuthenticodeSignature -LiteralPath $env:FERRET_SIGNED_FILE; '
      r'"$($s.Status)|$($s.SignerCertificate.Subject)"';

  final String _executable;
  final int _pid;
  final RunProcess _run;
  final StartDetached _detached;

  @override
  Future<InstallOutcome> install(File file) async {
    final here = await signatureOf(_executable);
    if (here.status != 'Valid' || here.subject.isEmpty) {
      throw UpdateRefused(.unsignedHere, here.toString());
    }

    final setup = await signatureOf(file.path);
    if (setup.status != 'Valid') {
      throw UpdateRefused(.notSigned, setup.toString());
    }

    if (setup.subject != here.subject) {
      throw UpdateRefused(.wrongPublisher, setup.toString());
    }

    final script = File(p.join(file.parent.path, 'ferret-update.ps1'));
    await script.writeAsString(
      updateScript(
        processId: _pid,
        setupPath: file.path,
        appPath: _executable,
        logPath: p.join(file.parent.path, 'ferret-update.log'),
      ),
    );
    await _detached('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script.path,
    ]);
    return .quitToRestart;
  }

  /// Windows' verdict on [path]'s signature.
  Future<({String status, String subject})> signatureOf(String path) async {
    final result = await _run(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-Command', _signatureScript],
      environment: {'FERRET_SIGNED_FILE': path},
    );
    final line = '${result.stdout}'.trim().split('\n').last.trim();
    final bar = line.indexOf('|');
    if (result.exitCode != 0 || bar < 0) {
      return (status: 'Unknown', subject: '');
    }

    return (status: line.substring(0, bar), subject: line.substring(bar + 1));
  }

  /// The helper: waits up to a minute for Ferret to quit, runs the setup
  /// and starts Ferret again, logging each step to [logPath].
  static String updateScript({
    required int processId,
    required String setupPath,
    required String appPath,
    required String logPath,
  }) {
    final arguments = setupArguments.map(_quote).join(', ');
    return '''
\$ErrorActionPreference = 'Stop'
\$log = ${_quote(logPath)}
function Log(\$message) {
  Add-Content -Path \$log -Value "[\$(Get-Date -Format s)] \$message" -ErrorAction SilentlyContinue
}

Log 'Waiting for Ferret to quit'
\$waited = 0
while (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
  if (\$waited -ge 60) {
    Log 'Ferret did not quit; update not installed'
    exit 1
  }
  Start-Sleep -Milliseconds 500
  \$waited += 0.5
}

Log 'Running the setup'
\$setup = Start-Process -FilePath ${_quote(setupPath)} -ArgumentList @($arguments) -Wait -PassThru
Log "Setup finished with \$(\$setup.ExitCode)"

Start-Process -FilePath ${_quote(appPath)}
Log 'Ferret started'
''';
  }

  /// A PowerShell string that takes [value] literally.
  static String _quote(String value) => "'${value.replaceAll("'", "''")}'";
}
