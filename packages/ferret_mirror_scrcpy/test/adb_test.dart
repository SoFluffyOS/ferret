import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdbDevice.parseList', () {
    const output = '''
* daemon not running; starting now at tcp:5037
* daemon started successfully
List of devices attached
emulator-5554          device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a transport_id:1
0123456789ABCDEF       unauthorized usb:1-1 transport_id:2
192.168.1.20:40123     device product:panther model:Pixel_7 device:panther transport_id:3
adb-0123456789-AbCdEf._adb-tls-connect._tcp device product:lynx model:Pixel_7a device:lynx transport_id:4
R58M12ABCDE            offline transport_id:5

''';

    test('reads every device and leaves the notices out', () {
      final devices = AdbDevice.parseList(output);

      expect(devices.map((device) => device.serial), [
        'emulator-5554',
        '0123456789ABCDEF',
        '192.168.1.20:40123',
        'adb-0123456789-AbCdEf._adb-tls-connect._tcp',
        'R58M12ABCDE',
      ]);
      expect(devices.map((device) => device.state), [
        AdbDeviceState.ready,
        AdbDeviceState.unauthorized,
        AdbDeviceState.ready,
        AdbDeviceState.ready,
        AdbDeviceState.offline,
      ]);
    });

    test('names a device by its model, or its serial without one', () {
      final devices = AdbDevice.parseList(output);

      expect(devices[2].name, 'Pixel 7');
      expect(devices[1].name, '0123456789ABCDEF');
    });

    test('knows which devices come over the network', () {
      final devices = AdbDevice.parseList(output);

      expect(devices.map((device) => device.isWireless), [
        false,
        false,
        true,
        true,
        false,
      ]);
      expect(
        const AdbDevice(serial: '[fe80::1%en0]:5555', state: .ready).isWireless,
        isTrue,
      );
    });

    test('reads Windows line endings and an empty list', () {
      expect(AdbDevice.parseList('List of devices attached\r\n\r\n'), isEmpty);
      expect(
        AdbDevice.parseList('List of devices attached\r\nabc\tdevice\r\n'),
        hasLength(1),
      );
    });
  });

  group('AdbLocator', () {
    AdbLocator locator({
      required String system,
      required Map<String, String> environment,
      required Set<String> files,
      List<String> extraDirectories = const [],
    }) {
      return AdbLocator(
        operatingSystem: system,
        environment: environment,
        exists: files.contains,
        extraDirectories: extraDirectories,
      );
    }

    test('prefers the folder it was given', () {
      final found = locator(
        system: 'macos',
        environment: {'PATH': '/usr/bin:/opt/tools'},
        files: {'/opt/tools/adb', '/ferret/platform-tools/adb'},
        extraDirectories: ['/ferret/platform-tools'],
      ).find();

      expect(found, '/ferret/platform-tools/adb');
    });

    test('looks on the PATH', () {
      final found = locator(
        system: 'linux',
        environment: {'PATH': '/usr/sbin:/opt/tools'},
        files: {'/opt/tools/adb'},
      ).find();

      expect(found, '/opt/tools/adb');
    });

    test('looks in the Android SDK the environment names', () {
      final found = locator(
        system: 'linux',
        environment: {'ANDROID_SDK_ROOT': '/sdk'},
        files: {'/sdk/platform-tools/adb'},
      ).find();

      expect(found, '/sdk/platform-tools/adb');
    });

    test('looks where Android Studio puts it on a Mac', () {
      final found = locator(
        system: 'macos',
        environment: {'HOME': '/Users/me'},
        files: {'/Users/me/Library/Android/sdk/platform-tools/adb'},
      ).find();

      expect(found, '/Users/me/Library/Android/sdk/platform-tools/adb');
    });

    test('looks for adb.exe on Windows, with its own separators', () {
      final found = locator(
        system: 'windows',
        environment: {
          'Path': r'C:\Windows;C:\tools',
          'LOCALAPPDATA': r'C:\Users\me\AppData\Local',
        },
        files: {
          r'C:\Users\me\AppData\Local\Android\Sdk\platform-tools\adb.exe',
        },
      ).find();

      expect(
        found,
        r'C:\Users\me\AppData\Local\Android\Sdk\platform-tools\adb.exe',
      );
    });

    test('finds nothing when adb is nowhere', () {
      final found = locator(
        system: 'linux',
        environment: {'PATH': '/usr/bin'},
        files: {},
      ).find();

      expect(found, isNull);
    });
  });

  group('PlatformToolsRelease', () {
    test('has a pinned download for each computer, none for phones', () {
      expect(
        PlatformToolsRelease.forSystem('macos')?.url,
        endsWith('-darwin.zip'),
      );
      expect(
        PlatformToolsRelease.forSystem('linux')?.url,
        endsWith('-linux.zip'),
      );
      expect(
        PlatformToolsRelease.forSystem('windows')?.url,
        endsWith('-win.zip'),
      );
      expect(PlatformToolsRelease.forSystem('android'), isNull);

      for (final system in const ['macos', 'linux', 'windows']) {
        final pinned = PlatformToolsRelease.forSystem(system);
        expect(pinned?.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(pinned?.url, startsWith('https://dl.google.com/'));
      }
    });
  });
}
