import 'dart:io';

import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory home;

  setUp(() async {
    home = await Directory.systemTemp.createTemp('ferret-login');
  });

  tearDown(() => home.delete(recursive: true));

  StartAtLogin linux({
    bool flatpak = false,
    List<bool>? portal,
    Map<String, String> environment = const {},
  }) => StartAtLogin(
    operatingSystem: 'linux',
    environment: {'HOME': home.path, ...environment},
    executable: '/opt/ferret/ferret',
    isFlatpak: () async => flatpak,
    requestBackground: (enabled) async => portal?.add(enabled),
  );

  test('on Linux, an autostart entry starts Ferret in the tray', () async {
    final login = linux();

    expect(await login.isEnabled(), isFalse);
    await login.setEnabled(true);

    expect(await login.isEnabled(), isTrue);
    expect(
      login.desktopFilePath,
      '${home.path}/.config/autostart/io.sofluffy.ferret.desktop',
    );
    final entry = await File(login.desktopFilePath).readAsString();
    expect(entry, contains('Exec="/opt/ferret/ferret" --hidden'));
    expect(entry, startsWith('[Desktop Entry]'));
  });

  test('from an AppImage, autostart runs the AppImage file', () async {
    final login = linux(
      environment: const {'APPIMAGE': '/home/someone/Apps/Ferret.AppImage'},
    );

    await login.setEnabled(true);

    final entry = await File(login.desktopFilePath).readAsString();
    expect(
      entry,
      contains('Exec="/home/someone/Apps/Ferret.AppImage" --hidden'),
    );
  });

  test('turning it off removes the entry', () async {
    final login = linux();
    await login.setEnabled(true);

    await login.setEnabled(false);

    expect(File(login.desktopFilePath).existsSync(), isFalse);
    await login.setEnabled(false);
  });

  test('inside a Flatpak the Background portal is asked instead', () async {
    final asked = <bool>[];
    final login = linux(flatpak: true, portal: asked);

    await login.setEnabled(true);

    expect(asked, [true]);
    expect(File(login.desktopFilePath).existsSync(), isFalse);
    expect(await login.isEnabled(remembered: true), isTrue);
  });

  test('on Windows, the Run key holds Ferret with --hidden', () async {
    final commands = <List<String>>[];
    final login = StartAtLogin(
      operatingSystem: 'windows',
      environment: const {},
      executable: r'C:\Program Files\Ferret\ferret.exe',
      run: (executable, arguments) async {
        commands.add([executable, ...arguments]);
        return ProcessResult(0, 0, '', '');
      },
    );

    await login.setEnabled(true);
    await login.setEnabled(false);
    final enabled = await login.isEnabled();

    expect(commands[0], [
      'reg',
      'add',
      StartAtLogin.runKey,
      '/v',
      'Ferret',
      '/t',
      'REG_SZ',
      '/d',
      r'"C:\Program Files\Ferret\ferret.exe" --hidden',
      '/f',
    ]);
    expect(commands[1].take(2), ['reg', 'delete']);
    expect(enabled, isTrue);
  });

  test('a Mac has none of this', () async {
    final login = StartAtLogin(operatingSystem: 'macos');

    expect(login.isSupported, isFalse);
    expect(await login.isEnabled(), isFalse);
  });
}
