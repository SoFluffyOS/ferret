import 'dart:io';

import 'package:ferret_remote_input/src/held_input.dart';
import 'package:ferret_remote_input/src/injector_status.dart';
import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/input_injector.dart';
import 'package:ferret_remote_input/src/linux/command_injector.dart';
import 'package:ferret_remote_input/src/linux/uinput_device.dart';
import 'package:ferret_remote_input/src/linux/uinput_syscalls.dart';
import 'package:ferret_remote_input/src/linux/us_layout.dart';

/// Injection on Linux, best first: a uinput virtual device when
/// `/dev/uinput` is writable (X11 and Wayland), else `ydotool` on Wayland
/// or `xdotool` on X11 when installed. Says plainly when none works.
class LinuxInjector implements InputInjector {
  LinuxInjector({
    UinputSyscalls? syscalls,
    Map<String, String>? environment,
    bool Function(String path)? exists,
    RunCommand? run,
  }) : _syscalls = syscalls ?? FfiUinputSyscalls(),
       _environment = environment ?? Platform.environment,
       _exists = exists ?? _existsOnDisk,
       _run = run;

  final UinputSyscalls _syscalls;
  final Map<String, String> _environment;
  final bool Function(String path) _exists;
  final RunCommand? _run;
  final HeldInput _held = HeldInput();

  UinputDevice? _uinput;
  CommandInjector? _command;

  @override
  Future<InjectorStatus> status() async {
    if (_uinput != null) {
      return const .ready(.uinput);
    }

    final device = _createUinput();
    final tool = _pickTool();
    _command = switch (tool) {
      final tool? => CommandInjector(tool, run: _run),
      null => null,
    };
    if (device != null) {
      _uinput = device;
      return const .ready(.uinput);
    }

    return switch (tool) {
      .xdotool => const .ready(.xdotool),
      .ydotool => const .ready(.ydotool),
      null when _onPath('ydotool') => const .unavailable(.ydotoolNotRunning),
      null => const .unavailable(.noLinuxBackend),
    };
  }

  @override
  Future<InjectorStatus> requestAccess() => status();

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> inject(List<InputAction> actions) async {
    final tracked = [
      for (final action in actions)
        if (_held.track(action)) action,
    ];
    await _send(tracked);
  }

  @override
  Future<void> releaseAll() async {
    await _send(_held.releaseAll());
    _command?.reset();
  }

  @override
  Future<void> dispose() async {
    await releaseAll();
    _uinput?.close();
    _uinput = null;
  }

  Future<void> _send(List<InputAction> actions) async {
    if (actions.isEmpty) {
      return;
    }

    final uinput = _uinput;
    final command = _command;
    if (uinput == null) {
      await command?.inject(actions);
      return;
    }

    var group = <InputAction>[];
    for (final action in actions) {
      if (action case TextAction(:final text)
          when command != null && !_typesOnUs(text)) {
        uinput.send(group);
        group = [];
        await command.inject([action]);
        continue;
      }

      group.add(action);
    }

    uinput.send(group);
  }

  /// A US keyboard types all of [text], so uinput can.
  bool _typesOnUs(String text) => text.runes.every(
    (rune) => UsLayout.keyOf(String.fromCharCode(rune)) != null,
  );

  UinputDevice? _createUinput() {
    try {
      return UinputDevice.create(_syscalls);
    } on Object {
      return null;
    }
  }

  CommandTool? _pickTool() {
    final hasX = (_environment['DISPLAY'] ?? '').isNotEmpty;
    final onWayland = (_environment['WAYLAND_DISPLAY'] ?? '').isNotEmpty;
    final xdotool = _onPath('xdotool') && hasX;
    final ydotool = _onPath('ydotool') && _ydotoolRunning();

    if (onWayland && ydotool) {
      return .ydotool;
    }

    if (xdotool) {
      return .xdotool;
    }

    if (ydotool) {
      return .ydotool;
    }

    return null;
  }

  bool _ydotoolRunning() {
    final runtime = _environment['XDG_RUNTIME_DIR'] ?? '';
    final sockets = [
      ?_environment['YDOTOOL_SOCKET'],
      if (runtime.isNotEmpty) '$runtime/.ydotool_socket',
      '/tmp/.ydotool_socket',
    ];
    return sockets.any(_exists);
  }

  bool _onPath(String executable) {
    final directories = (_environment['PATH'] ?? '/usr/bin:/bin').split(':');
    return directories.any(
      (directory) => directory.isNotEmpty && _exists('$directory/$executable'),
    );
  }

  static bool _existsOnDisk(String path) =>
      FileSystemEntity.typeSync(path) != .notFound;
}
