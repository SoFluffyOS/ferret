import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter_test/flutter_test.dart';

Future<InstallKind> _detect(
  String os, {
  String executable = '',
  Map<String, String> environment = const {},
  bool release = true,
  String? installer,
  bool storeBuild = false,
  Set<String> files = const {},
}) => InstallKind.detect(
  operatingSystem: os,
  executable: executable,
  environment: environment,
  isReleaseBuild: release,
  androidInstaller: installer,
  storeBuild: storeBuild,
  exists: (path) async => files.contains(path),
);

void main() {
  test('a Mac app updates itself; a build run does not', () async {
    expect(
      await _detect(
        'macos',
        executable: '/Applications/Ferret.app/Contents/MacOS/ferret',
      ),
      InstallKind.macApp,
    );
    expect(
      await _detect(
        'macos',
        executable: '/Applications/Ferret.app/Contents/MacOS/ferret',
        release: false,
      ),
      InstallKind.manual,
    );
  });

  test('Windows updates itself only where its setup installed it', () async {
    const exe = r'C:\Users\a\AppData\Local\Programs\Ferret\ferret.exe';
    expect(
      await _detect(
        'windows',
        executable: exe,
        files: {r'C:\Users\a\AppData\Local\Programs\Ferret\unins000.exe'},
      ),
      InstallKind.windowsSetup,
    );
    expect(await _detect('windows', executable: exe), InstallKind.manual);
    expect(
      await _detect(
        'windows',
        executable: r'C:\Program Files\WindowsApps\Ferret_1.0\ferret.exe',
      ),
      InstallKind.store,
    );
  });

  test(
    'Linux: AppImage yes, Flatpak and .deb to the package manager',
    () async {
      expect(
        await _detect(
          'linux',
          executable: '/tmp/.mount_FerretX/usr/lib/ferret/ferret',
          environment: {
            'APPIMAGE': '/home/a/.local/opt/ferret/Ferret.AppImage',
          },
        ),
        InstallKind.linuxAppImage,
      );
      expect(
        await _detect(
          'linux',
          executable: '/app/lib/ferret/ferret',
          environment: {'FLATPAK_ID': 'io.sofluffy.ferret'},
        ),
        InstallKind.packageManager,
      );
      expect(
        await _detect('linux', executable: '/usr/lib/ferret/ferret'),
        InstallKind.packageManager,
      );
      expect(
        await _detect('linux', executable: '/home/a/ferret/ferret'),
        InstallKind.manual,
      );
    },
  );

  test('Android: the APK yes, a store install never checks', () async {
    expect(await _detect('android'), InstallKind.androidApk);
    expect(
      await _detect(
        'android',
        installer: 'com.google.android.packageinstaller',
      ),
      InstallKind.androidApk,
    );
    expect(
      await _detect('android', installer: 'com.android.vending'),
      InstallKind.store,
    );
    expect(InstallKind.store.checks, isFalse);
  });

  test('a Play build never updates itself, even sideloaded', () async {
    expect(await _detect('android', storeBuild: true), InstallKind.store);
    expect(
      await _detect(
        'android',
        installer: 'com.google.android.packageinstaller',
        storeBuild: true,
      ),
      InstallKind.store,
    );
  });

  test('iPhone never checks', () async {
    expect(await _detect('ios'), InstallKind.store);
  });
}
