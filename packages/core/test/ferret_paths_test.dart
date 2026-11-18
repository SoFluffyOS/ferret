import 'dart:io';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('resolve', () {
    test('uses ~/.sofluffy/ferret on macOS and Linux', () async {
      for (final system in ['macos', 'linux']) {
        final paths = await FerretPaths.resolve(
          environment: const {'HOME': '/home/me'},
          operatingSystem: system,
        );

        expect(paths.root, '/home/me/.sofluffy/ferret');
      }
    });

    test('uses USERPROFILE on Windows', () async {
      final paths = await FerretPaths.resolve(
        environment: const {
          'USERPROFILE': r'C:\Users\me',
          'APPDATA': r'C:\Users\me\AppData\Roaming',
        },
        operatingSystem: 'windows',
      );

      expect(paths.root, r'C:\Users\me\.sofluffy\ferret');
      expect(
        paths.feature('drop'),
        r'C:\Users\me\.sofluffy\ferret\features\drop',
      );
    });

    test('asks the platform for the folder on phones', () async {
      for (final system in ['android', 'ios']) {
        final paths = await FerretPaths.resolve(
          environment: const {'HOME': '/home/me'},
          operatingSystem: system,
          phoneDirectory: () async => '/data/app/files',
        );

        expect(paths.root, '/data/app/files');
      }
    });

    test('fails on a phone without the platform folder', () {
      expect(
        FerretPaths.resolve(environment: const {}, operatingSystem: 'ios'),
        throwsStateError,
      );
    });

    test('fails on a computer without a home folder', () {
      expect(
        FerretPaths.resolve(environment: const {}, operatingSystem: 'linux'),
        throwsStateError,
      );
    });

    test('FERRET_HOME replaces the root everywhere', () async {
      for (final system in ['macos', 'linux', 'windows', 'android']) {
        final paths = await FerretPaths.resolve(
          environment: const {'HOME': '/home/me', 'FERRET_HOME': '/tmp/f'},
          operatingSystem: system,
          phoneDirectory: () async => '/data/app/files',
        );

        expect(paths.root, '/tmp/f');
      }
    });
  });

  test('names a folder for each kind of file', () async {
    final paths = await FerretPaths.resolve(
      environment: const {'HOME': '/Users/me'},
      operatingSystem: 'macos',
    );

    expect(paths.settings, '/Users/me/.sofluffy/ferret/settings');
    expect(paths.secrets, '/Users/me/.sofluffy/ferret/secrets');
    expect(paths.tools, '/Users/me/.sofluffy/ferret/tools');
    expect(paths.cache, '/Users/me/.sofluffy/ferret/cache');
    expect(paths.logs, '/Users/me/.sofluffy/ferret/logs');
    expect(
      paths.feature('messages'),
      '/Users/me/.sofluffy/ferret/features/messages',
    );
    expect(
      paths.nested('cli').secrets,
      '/Users/me/.sofluffy/ferret/cli/secrets',
    );
  });

  test('creates folders only this user can open', () async {
    final temporary = await Directory.systemTemp.createTemp('ferret_paths');
    addTearDown(() => temporary.delete(recursive: true));
    final paths = FerretPaths('${temporary.path}/ferret');

    final folder = await paths.create(paths.feature('drop'));

    expect(await folder.exists(), isTrue);
    if (!Platform.isWindows) {
      for (final created in [
        paths.root,
        '${paths.root}/features',
        paths.feature('drop'),
      ]) {
        expect((await Directory(created).stat()).modeString(), 'rwx------');
      }
    }
  });
}
