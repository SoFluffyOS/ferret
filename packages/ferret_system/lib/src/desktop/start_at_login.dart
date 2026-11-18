import 'dart:io';

import 'package:dbus/dbus.dart';

/// Runs a command and reports how it ended.
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Starts Ferret when the user logs in, in the tray (`--hidden`).
///
/// Linux: an XDG autostart entry in `~/.config/autostart`, which every
/// desktop reads; inside a Flatpak, the Background portal instead.
/// Windows: the user's `Run` key. Turning it off removes what was added, so
/// nothing is left outside Ferret's own folder.
class StartAtLogin {
  StartAtLogin({
    String? operatingSystem,
    Map<String, String>? environment,
    String? executable,
    RunProcess? run,
    Future<bool> Function()? isFlatpak,
    Future<void> Function(bool enabled)? requestBackground,
  }) : _operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _environment = environment ?? Platform.environment,
       _executable = executable ?? Platform.resolvedExecutable,
       _run = run ?? Process.run,
       _isFlatpak = isFlatpak ?? (() => File('/.flatpak-info').exists()),
       _requestBackground = requestBackground ?? _portalRequest;

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

  bool get isSupported =>
      _operatingSystem == 'linux' || _operatingSystem == 'windows';

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
    'Exec="$_executable" $hiddenArgument',
    'Icon=io.sofluffy.ferret',
    'Terminal=false',
    'X-GNOME-Autostart-enabled=true',
    '',
  ].join('\n');

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
      '"$_executable" $hiddenArgument',
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
}
