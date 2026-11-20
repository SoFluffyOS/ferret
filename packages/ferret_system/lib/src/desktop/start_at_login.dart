import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:ferret_system/src/messages.g.dart';

/// Runs a command and reports how it ended.
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Starts Ferret when the user logs in, in the tray (`--hidden`).
///
/// Linux: an XDG autostart entry in `~/.config/autostart`, which every
/// desktop reads; inside a Flatpak, the Background portal instead.
/// Windows: the user's `Run` key. macOS 13 and later: a login item for the
/// app itself. Turning it off removes what was added, so nothing is left
/// outside Ferret's own folder.
class StartAtLogin {
  StartAtLogin({
    String? operatingSystem,
    Map<String, String>? environment,
    String? executable,
    RunProcess? run,
    Future<bool> Function()? isFlatpak,
    Future<void> Function(bool enabled)? requestBackground,
    Future<bool> Function()? isLoginItem,
    Future<bool> Function(bool enabled)? setLoginItem,
  }) : _operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _environment = environment ?? Platform.environment,
       _executable = executable ?? Platform.resolvedExecutable,
       _run = run ?? Process.run,
       _isFlatpak = isFlatpak ?? (() => File('/.flatpak-info').exists()),
       _requestBackground = requestBackground ?? _portalRequest,
       _isLoginItem = isLoginItem ?? SystemHostApi().isLoginItem,
       _setLoginItem = setLoginItem ?? SystemHostApi().setLoginItem;

  static const desktopFileName = 'io.sofluffy.ferret.desktop';
  static const runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const runValue = 'Ferret';
  static const hiddenArgument = '--hidden';

  final String _operatingSystem;
  final Map<String, String> _environment;
  final String _executable;
  final RunProcess _run;
  final Future<bool> Function() _isFlatpak;
  final Future<void> Function(bool enabled) _requestBackground;
  final Future<bool> Function() _isLoginItem;
  final Future<bool> Function(bool enabled) _setLoginItem;

  bool get isSupported => switch (_operatingSystem) {
    'linux' || 'windows' || 'macos' => true,
    _ => false,
  };

  /// Where the Linux autostart entry goes.
  String get desktopFilePath {
    final home = _environment['HOME'] ?? '';
    final config = switch (_environment['XDG_CONFIG_HOME']) {
      final String path when path.isNotEmpty => path,
      _ => '$home/.config',
    };
    return '$config/autostart/$desktopFileName';
  }

  /// The autostart entry: Ferret itself, started in the tray.
  String get desktopEntry => [
    '[Desktop Entry]',
    'Type=Application',
    'Name=Ferret',
    'Comment=Continue what you were doing on any of your devices',
    'Exec="$_launcher" $hiddenArgument',
    'Icon=io.sofluffy.ferret',
    'Terminal=false',
    'X-GNOME-Autostart-enabled=true',
    '',
  ].join('\n');

  /// What autostart runs. An AppImage's binary sits in a mount that moves
  /// every run, so the AppImage file itself, which `APPIMAGE` names.
  String get _launcher => switch (_environment['APPIMAGE']) {
    final String appImage when appImage.isNotEmpty => appImage,
    _ => _executable,
  };

  /// What the Run key starts. An MSIX install lives in a folder named
  /// after its version, gone after the next update, so the Run key points
  /// at its `ferret.exe` app execution alias, which follows updates.
  String get _windowsLauncher {
    final localAppData = _environment['LOCALAPPDATA'] ?? '';
    final packaged = _executable.toLowerCase().contains(r'\windowsapps\');
    if (!packaged || localAppData.isEmpty) {
      return _executable;
    }

    return '$localAppData\\Microsoft\\WindowsApps\\ferret.exe';
  }

  /// Whether Ferret starts at login. Inside a Flatpak the portal keeps
  /// this, so [remembered] answers.
  Future<bool> isEnabled({bool remembered = false}) async {
    if (_operatingSystem == 'windows') {
      final result = await _quietly('reg', [
        'query',
        runKey,
        '/v',
        runValue,
      ]);
      return result?.exitCode == 0;
    }

    if (_operatingSystem == 'macos') {
      return _quietlyAsk(_isLoginItem);
    }

    if (_operatingSystem != 'linux') {
      return false;
    }

    if (await _isFlatpak()) {
      return remembered;
    }

    return File(desktopFilePath).exists();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_operatingSystem == 'windows') {
      await _setRunKey(enabled);
      return;
    }

    if (_operatingSystem == 'macos') {
      await _quietlyAsk(() => _setLoginItem(enabled));
      return;
    }

    if (_operatingSystem != 'linux') {
      return;
    }

    if (await _isFlatpak()) {
      await _requestBackground(enabled);
      return;
    }

    final file = File(desktopFilePath);
    if (!enabled) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(desktopEntry);
  }

  Future<void> _setRunKey(bool enabled) async {
    if (!enabled) {
      await _quietly('reg', ['delete', runKey, '/v', runValue, '/f']);
      return;
    }

    await _quietly('reg', [
      'add',
      runKey,
      '/v',
      runValue,
      '/t',
      'REG_SZ',
      '/d',
      '"$_windowsLauncher" $hiddenArgument',
      '/f',
    ]);
  }

  Future<ProcessResult?> _quietly(
    String executable,
    List<String> arguments,
  ) async {
    try {
      return await _run(executable, arguments);
    } on ProcessException {
      return null;
    }
  }

  /// Asks the desktop, through the Background portal, to start the Flatpak
  /// at login. The answer comes later as a signal; the switch already shows
  /// what was asked.
  static Future<void> _portalRequest(bool enabled) async {
    DBusClient? client;
    try {
      final session = DBusClient.session();
      client = session;
      await session.callMethod(
        destination: 'org.freedesktop.portal.Desktop',
        path: DBusObjectPath('/org/freedesktop/portal/desktop'),
        interface: 'org.freedesktop.portal.Background',
        name: 'RequestBackground',
        values: [
          const DBusString(''),
          DBusDict.stringVariant({
            'reason': const DBusString('Start Ferret when you log in'),
            'autostart': DBusBoolean(enabled),
            'commandline': DBusArray.string(const ['ferret', hiddenArgument]),
          }),
        ],
        replySignature: DBusSignature('o'),
      );
    } on Object {
      return;
    } finally {
      await client?.close();
    }
  }

  /// The system's answer, or false when the plugin isn't there.
  static Future<bool> _quietlyAsk(Future<bool> Function() ask) async {
    try {
      return await ask();
    } on Object {
      return false;
    }
  }
}
