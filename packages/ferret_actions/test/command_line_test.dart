import 'package:ferret_actions/ferret_actions.dart';
import 'package:test/test.dart';

void main() {
  group('CommandLine.split', () {
    test('splits at spaces', () {
      expect(CommandLine.split('  say   hello world '), [
        'say',
        'hello',
        'world',
      ]);
    });

    test('quotes keep words together', () {
      expect(
        CommandLine.split('''shortcuts run "Good night" 'a "b" c' '''),
        ['shortcuts', 'run', 'Good night', 'a "b" c'],
      );
    });

    test('an empty pair of quotes is an empty argument', () {
      expect(CommandLine.split('echo ""'), ['echo', '']);
    });

    test('a backslash keeps a space', () {
      expect(
        CommandLine.split(r'open /Volumes/My\ Disk', backslashEscapes: true),
        ['open', '/Volumes/My Disk'],
      );
    });

    test('a backslash is a folder separator on Windows', () {
      expect(
        CommandLine.split(r'C:\Tools\backup.exe /q', backslashEscapes: false),
        [r'C:\Tools\backup.exe', '/q'],
      );
    });

    test('shell characters mean nothing', () {
      expect(CommandLine.split(r'echo hi; rm -rf $HOME | cat'), [
        'echo',
        'hi;',
        'rm',
        '-rf',
        r'$HOME',
        '|',
        'cat',
      ]);
    });
  });

  group('CommandLine.resolve', () {
    test('a plain program starts as it is', () {
      expect(
        CommandLine.resolve(
          ['say', 'hello'],
          home: '/Users/me',
          operatingSystem: 'macos',
        ),
        ['say', 'hello'],
      );
    });

    test('a leading ~ is the home folder', () {
      expect(
        CommandLine.resolve(
          ['~/bin/backup', '~', 'a~b'],
          home: '/home/me',
          operatingSystem: 'linux',
        ),
        ['/home/me/bin/backup', '/home/me', 'a~b'],
      );
    });

    test('scripts get the program that runs them', () {
      expect(
        CommandLine.resolve(
          ['~/night.sh'],
          home: '/home/me',
          operatingSystem: 'linux',
        ),
        ['/bin/sh', '/home/me/night.sh'],
      );
      expect(
        CommandLine.resolve(
          ['/Users/me/Night.scpt'],
          home: '/Users/me',
          operatingSystem: 'macos',
        ),
        ['/usr/bin/osascript', '/Users/me/Night.scpt'],
      );
      expect(
        CommandLine.resolve(
          ['/Applications/Music.app'],
          home: '/Users/me',
          operatingSystem: 'macos',
        ),
        ['/usr/bin/open', '/Applications/Music.app'],
      );
    });

    test('Windows scripts and shortcuts', () {
      expect(
        CommandLine.resolve(
          [r'C:\Tools\night.ps1', '-Quiet'],
          home: r'C:\Users\me',
          operatingSystem: 'windows',
        ),
        [
          'powershell',
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          r'C:\Tools\night.ps1',
          '-Quiet',
        ],
      );
      expect(
        CommandLine.resolve(
          [r'~\Desktop\Backup.lnk'],
          home: r'C:\Users\me',
          operatingSystem: 'windows',
        ),
        ['cmd', '/c', r'C:\Users\me\Desktop\Backup.lnk'],
      );
    });

    test('nothing in, nothing out', () {
      expect(CommandLine.resolve(const []), isEmpty);
    });
  });
}
