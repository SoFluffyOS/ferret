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
}

RunCommand _commands(Map<String, ProcessResult> results) =>
    (executable, arguments) async =>
        results['$executable ${arguments.join(' ')}'] ??
        ProcessResult(0, 1, Uint8List(0), '');

ProcessResult _ok(String stdout) =>
    ProcessResult(0, 0, Uint8List.fromList(utf8.encode(stdout)), '');
