import 'dart:io';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'uinput_test.dart' show FakeSyscalls;

void main() {
  LinuxInjector injectorWith({
    bool uinput = false,
    Map<String, String> environment = const {},
    Set<String> files = const {},
    List<(String, List<String>)>? runs,
  }) => LinuxInjector(
    syscalls: FakeSyscalls()..writable = uinput,
    environment: {'PATH': '/usr/bin', ...environment},
    exists: files.contains,
    run: (executable, arguments) async {
      runs?.add((executable, arguments));
      return ProcessResult(0, 0, '', '');
    },
  );

  test('uinput comes first when it is writable', () async {
    expect(
      await injectorWith(uinput: true, files: {'/usr/bin/xdotool'}).status(),
      const InjectorStatus.ready(.uinput),
    );
  });

  test('xdotool on X11', () async {
    expect(
      await injectorWith(
        environment: {'DISPLAY': ':0'},
        files: {'/usr/bin/xdotool'},
      ).status(),
      const InjectorStatus.ready(.xdotool),
    );
  });

  test('ydotool on Wayland, when its daemon runs', () async {
    final injector = injectorWith(
      environment: {
        'DISPLAY': ':0',
        'WAYLAND_DISPLAY': 'wayland-0',
        'XDG_RUNTIME_DIR': '/run/user/1000',
      },
      files: {
        '/usr/bin/xdotool',
        '/usr/bin/ydotool',
        '/run/user/1000/.ydotool_socket',
      },
    );

    expect(await injector.status(), const InjectorStatus.ready(.ydotool));
  });

  test('xdotool without an X display does not count', () async {
    expect(
      await injectorWith(files: {'/usr/bin/xdotool'}).status(),
      const InjectorStatus.unavailable(.noLinuxBackend),
    );
  });

  test('says when ydotool is there but its daemon is not', () async {
    expect(
      await injectorWith(
        environment: {'WAYLAND_DISPLAY': 'wayland-0'},
        files: {'/usr/bin/ydotool'},
      ).status(),
      const InjectorStatus.unavailable(.ydotoolNotRunning),
    );
  });

  test('says when nothing works', () async {
    expect(
      await injectorWith().status(),
      const InjectorStatus.unavailable(.noLinuxBackend),
    );
  });

  test('text a US layout cannot type goes through the tool', () async {
    final runs = <(String, List<String>)>[];
    final injector = injectorWith(
      uinput: true,
      environment: {'DISPLAY': ':0'},
      files: {'/usr/bin/xdotool'},
      runs: runs,
    );
    await injector.status();

    await injector.inject(const [TextAction('ok'), TextAction('café')]);

    expect(runs.map(_line), ['xdotool type --delay 0 -- café']);
  });

  test('release all lets go of a held button through the tool', () async {
    final runs = <(String, List<String>)>[];
    final injector = injectorWith(
      environment: {'DISPLAY': ':0'},
      files: {'/usr/bin/xdotool'},
      runs: runs,
    );
    await injector.status();
    await injector.inject(const [ButtonAction(.left, pressed: true)]);

    await injector.releaseAll();

    expect(_line(runs.last), 'xdotool mouseup 1');
  });
}

String _line((String, List<String>) run) => [run.$1, ...run.$2].join(' ');
