import 'dart:io';

import 'package:dbus/dbus.dart';
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
    bool portalSaysYes = true,
    Map<String, String> environment = const {},
  }) => StartAtLogin(
    operatingSystem: 'linux',
    environment: {'HOME': home.path, ...environment},
    executable: '/opt/ferret/ferret',
    isFlatpak: () async => flatpak,
    requestBackground: (enabled) async {
      portal?.add(enabled);
      return portalSaysYes;
    },
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

  test('inside a Flatpak, a no from the desktop is reported', () async {
    final login = linux(flatpak: true, portalSaysYes: false);

    expect(await login.setEnabled(true), isFalse);
  });

  group("the Background portal's answer", () {
    DBusDict results(bool autostart) => DBusDict.stringVariant({
      'background': const DBusBoolean(true),
      'autostart': DBusBoolean(autostart),
    });

    test('yes with autostart is a yes', () {
      expect(
        StartAtLogin.backgroundAllowed([
          const DBusUint32(0),
          results(true),
        ], enabled: true),
        isTrue,
      );
    });

    test('a cancelled dialog or autostart left off is a no', () {
      expect(
        StartAtLogin.backgroundAllowed([
          const DBusUint32(1),
          results(true),
        ], enabled: true),
        isFalse,
      );
      expect(
        StartAtLogin.backgroundAllowed([
          const DBusUint32(0),
          results(false),
        ], enabled: true),
        isFalse,
      );
    });

    test('turning it off always goes through', () {
      expect(
        StartAtLogin.backgroundAllowed([
          const DBusUint32(2),
          results(false),
        ], enabled: false),
        isTrue,
      );
    });
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

  test('an MSIX install starts through its app execution alias', () async {
    final commands = <List<String>>[];
    final login = StartAtLogin(
      operatingSystem: 'windows',
      environment: const {'LOCALAPPDATA': r'C:\Users\sam\AppData\Local'},
      executable:
          r'C:\Program Files\WindowsApps\io.sofluffy.ferret_0.1.0.0_x64__abc'
          r'\ferret.exe',
      run: (executable, arguments) async {
        commands.add([executable, ...arguments]);
        return ProcessResult(0, 0, '', '');
      },
    );

    await login.setEnabled(true);

    expect(
      commands.single,
      contains(
        r'"C:\Users\sam\AppData\Local\Microsoft\WindowsApps\ferret.exe" '
        '--hidden',
      ),
    );
  });

  test('on a Mac, a login item for the app itself', () async {
    var item = false;
    final login = StartAtLogin(
      operatingSystem: 'macos',
      isLoginItem: () async => item,
      setLoginItem: (enabled) async {
        item = enabled;
        return true;
      },
    );

    expect(login.isSupported, isTrue);
    expect(await login.isEnabled(), isFalse);
    await login.setEnabled(true);
    expect(await login.isEnabled(), isTrue);
    await login.setEnabled(false);
    expect(await login.isEnabled(), isFalse);
  });

  test('a Mac without the plugin says off, quietly', () async {
    final login = StartAtLogin(
      operatingSystem: 'macos',
      isLoginItem: () async => throw StateError('no plugin'),
    );

    expect(await login.isEnabled(), isFalse);
  });
}
