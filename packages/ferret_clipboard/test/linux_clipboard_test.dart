import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'text comes from the text clipboard, with the KDE password hint',
    () async {
      final clipboard = LinuxClipboard(
        environment: const {'DISPLAY': ':0'},
        run: _commands({
          'xclip -selection clipboard -t TARGETS -o': _ok(
            'UTF8_STRING\nx-kde-passwordManagerHint\n',
          ),
        }),
        readText: () async => 'hunter2',
      );

      final content = await clipboard.read();

      expect(content?.text, 'hunter2');
      expect(content?.sensitive, isTrue);
    },
  );

  test('images are read with wl-paste on Wayland', () async {
    final png = Uint8List.fromList([137, 80, 78, 71]);
    final clipboard = LinuxClipboard(
      environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
      run: _commands({
        'wl-paste --list-types': _ok('image/jpeg\nimage/png\n'),
        'wl-paste --no-newline --type image/png': ProcessResult(0, 0, png, ''),
      }),
      readText: () async => null,
    );

    final content = await clipboard.read();

    expect(content?.image, png);
    expect(content?.imageMime, 'image/png');
    expect(content?.sensitive, isFalse);
  });

  test('without xclip, images are skipped instead of failing', () async {
    final clipboard = LinuxClipboard(
      environment: const {'DISPLAY': ':0'},
      run: (_, _) => throw const ProcessException('xclip', []),
      readText: () async => null,
    );

    expect(await clipboard.read(), isNull);
  });

  test('writing text uses the text clipboard', () async {
    String? written;
    final clipboard = LinuxClipboard(
      environment: const {'DISPLAY': ':0'},
      writeText: (text) async => written = text,
    );

    await clipboard.write(const .text('hi'));

    expect(written, 'hi');
  });

  test('writing an image without a tool says what to install', () async {
    final clipboard = LinuxClipboard(
      environment: const {'DISPLAY': ':0'},
      start: (_, _) => throw const ProcessException('xclip', []),
    );

    await expectLater(
      clipboard.write(.image(Uint8List(4), imageMime: 'image/png')),
      throwsA(isA<ClipboardToolMissingException>()),
    );
  });

  test('a JPEG goes on as PNG, which most apps paste', () async {
    final types = <String>[];
    final png = Uint8List.fromList([137, 80, 78, 71]);
    final clipboard = LinuxClipboard(
      environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
      toPng: (_) async => png,
      start: (_, arguments) {
        types.add(arguments.last);
        throw const ProcessException('wl-copy', []);
      },
    );

    await expectLater(
      clipboard.write(.image(Uint8List(4), imageMime: 'image/jpeg')),
      throwsA(isA<ClipboardToolMissingException>()),
    );

    expect(types, ['image/png']);
  });

  test("a JPEG that can't be turned into PNG goes on as it is", () async {
    final types = <String>[];
    final clipboard = LinuxClipboard(
      environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
      toPng: (_) async => null,
      start: (_, arguments) {
        types.add(arguments.last);
        throw const ProcessException('wl-copy', []);
      },
    );

    await expectLater(
      clipboard.write(.image(Uint8List(4), imageMime: 'image/jpeg')),
      throwsA(isA<ClipboardToolMissingException>()),
    );

    expect(types, ['image/jpeg']);
  });

  test('polling reports a change once per new content', () async {
    var text = 'one';
    final clipboard = LinuxClipboard(
      environment: const {'DISPLAY': ':0'},
      run: _commands({}),
      readText: () async => text,
      pollInterval: const Duration(milliseconds: 10),
    );
    var changes = 0;
    final subscription = clipboard.changes.listen((_) => changes++);

    await clipboard.startWatching();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    text = 'two';
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await clipboard.stopWatching();
    await subscription.cancel();

    expect(changes, 1);
  });

  test('on Wayland, a read asks wl-paste first, so a copy made in the '
      'background is not missed', () async {
    final clipboard = LinuxClipboard(
      environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
      run: _commands({'wl-paste --no-newline --type text': _ok('fresh')}),
      readText: () async => 'stale',
    );

    expect((await clipboard.read())?.text, 'fresh');
  });

  test('where wl-paste --watch exits at once, as on GNOME, copies are only '
      'noticed while focused', () async {
    final clipboard = LinuxClipboard(
      environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
      run: _commands({}),
      start: (_, _) => Process.start('true', const []),
      readText: () async => '',
      pollInterval: const Duration(seconds: 5),
    );

    expect(clipboard.access, ClipboardAccess.always);
    await clipboard.startWatching();
    await clipboard.stopWatching();

    expect(clipboard.access, ClipboardAccess.whileFocused);
    expect(clipboard.access.watchesOtherApps, isFalse);
  });

  test('where the copy can only be read while focused, polling never runs '
      'wl-paste, which would take focus from the window in front', () async {
    final commands = <String>[];
    var text = 'one';
    final clipboard = LinuxClipboard(
      environment: const {'WAYLAND_DISPLAY': 'wayland-0'},
      run: (executable, arguments) async {
        commands.add('$executable ${arguments.join(' ')}');
        return ProcessResult(0, 1, Uint8List(0), '');
      },
      start: (_, _) => Process.start('true', const []),
      readText: () async => text,
      pollInterval: const Duration(milliseconds: 10),
    );
    var changes = 0;
    final subscription = clipboard.changes.listen((_) => changes++);

    await clipboard.startWatching();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    text = 'two';
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await clipboard.stopWatching();
    await subscription.cancel();

    expect(clipboard.access, ClipboardAccess.whileFocused);
    expect(changes, 1);
    expect(commands.where((command) => command.startsWith('wl-paste')), []);
  });

  test('on X11 the clipboard is always watched', () async {
    final clipboard = LinuxClipboard(
      environment: const {'DISPLAY': ':0'},
      run: _commands({}),
      readText: () async => '',
      pollInterval: const Duration(seconds: 5),
    );

    await clipboard.startWatching();
    await clipboard.stopWatching();

    expect(clipboard.access, ClipboardAccess.always);
  });
}

RunCommand _commands(Map<String, ProcessResult> results) =>
    (executable, arguments) async =>
        results['$executable ${arguments.join(' ')}'] ??
        ProcessResult(0, 1, Uint8List(0), '');

ProcessResult _ok(String stdout) =>
    ProcessResult(0, 0, Uint8List.fromList(utf8.encode(stdout)), '');
