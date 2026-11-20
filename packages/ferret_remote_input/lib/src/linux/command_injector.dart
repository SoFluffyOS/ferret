import 'dart:async';
import 'dart:io';

import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/key_chords.dart';
import 'package:ferret_remote_input/src/keys/keys.dart';

/// Runs a command and waits for it.
typedef RunCommand = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

enum CommandTool { xdotool, ydotool }

/// Injects by running `xdotool` (X11) or `ydotool` (1.0 or later, through
/// its `ydotoold` daemon). Commands run one at a time; moves that pile up
/// while one runs are merged, so a slow machine lags less instead of more.
class CommandInjector {
  CommandInjector(this.tool, {RunCommand? run}) : _run = run ?? Process.run;

  /// Pixels of scrolling per wheel notch.
  static const pixelsPerNotch = 40;

  final CommandTool tool;
  final RunCommand _run;
  final List<InputAction> _queue = [];
  final KeyChords _chords = KeyChords(LinuxKeyCodes.modifiers);
  final Map<InputKey, Set<KeyModifier>> _heldModifiers = {};

  /// xdotool: the modifier keys held on their own.
  Set<KeyModifier> _latched = const {};
  Future<void>? _draining;
  int _scrollX = 0;
  int _scrollY = 0;

  /// The last command failed, such as when the tool was uninstalled.
  bool failing = false;

  String get executable => tool.name;

  /// Queues [actions]; completes when they and anything queued before ran.
  Future<void> inject(List<InputAction> actions) {
    _queue.addAll(actions);
    return _draining ??= _drain().whenComplete(() => _draining = null);
  }

  /// The command lines for [actions], merged and in order.
  List<List<String>> commandsOf(List<InputAction> actions) {
    final merged = merge(actions);
    return switch (tool) {
      .xdotool => _xdotool(merged),
      .ydotool => _ydotool(merged),
    };
  }

  void reset() {
    _chords.reset();
    _heldModifiers.clear();
    _latched = const {};
  }

  /// Adds up neighbouring moves and neighbouring scrolls.
  static List<InputAction> merge(List<InputAction> actions) {
    final merged = <InputAction>[];
    for (final action in actions) {
      final previous = switch (merged) {
        [..., final last] => last,
        _ => null,
      };
      switch ((previous, action)) {
        case (
          MoveAction(dx: final x, dy: final y),
          MoveAction(:final dx, :final dy),
        ):
          merged[merged.length - 1] = MoveAction(x + dx, y + dy);
        case (
          ScrollAction(dx: final x, dy: final y),
          ScrollAction(:final dx, :final dy),
        ):
          merged[merged.length - 1] = ScrollAction(x + dx, y + dy);
        default:
          merged.add(action);
      }
    }

    return merged;
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final actions = List<InputAction>.of(_queue);
      _queue.clear();
      for (final arguments in commandsOf(actions)) {
        await _runOne(arguments);
      }
    }
  }

  Future<void> _runOne(List<String> arguments) async {
    try {
      final result = await _run(executable, arguments);
      failing = result.exitCode != 0;
    } on Object {
      failing = true;
    }
  }

  /// xdotool chains commands in one run, but `type` takes every argument
  /// after it, so text ends a run.
  List<List<String>> _xdotool(List<InputAction> actions) {
    final runs = <List<String>>[];
    var current = <String>[];
    for (final action in actions) {
      switch (action) {
        case MoveAction(:final dx, :final dy):
          current.addAll(['mousemove_relative', '--', '$dx', '$dy']);
        case ScrollAction(:final dx, :final dy):
          current.addAll(_xdotoolScroll(dx, dy));
        case ButtonAction(:final button, :final pressed):
          current.addAll([
            switch (pressed) {
              true => 'mousedown',
              false => 'mouseup',
            },
            _xdotoolButton(button),
          ]);
        case KeyAction(:final key, :final pressed, :final modifiers):
          final chord = _xdotoolChord(key, pressed, modifiers);
          if (chord == null) {
            continue;
          }

          current.addAll([
            switch (pressed) {
              true => 'keydown',
              false => 'keyup',
            },
            chord,
          ]);
        case TextAction(:final text):
          if (text.isEmpty) {
            continue;
          }

          current.addAll(['type', '--delay', '0', '--', text]);
          runs.add(current);
          current = [];
        case ModifiersAction(:final held):
          current.addAll(_xdotoolLatch(held));
      }
    }

    if (current.isNotEmpty) {
      runs.add(current);
    }

    return runs;
  }

  List<String> _xdotoolScroll(int dx, int dy) {
    final (notchesX, notchesY) = _notches(dx, dy);
    final down = switch (notchesY > 0) {
      true => '5',
      false => '4',
    };
    final right = switch (notchesX > 0) {
      true => '7',
      false => '6',
    };

    return [
      if (notchesY != 0) ...[
        'click',
        '--repeat',
        '${notchesY.abs()}',
        '--delay',
        '1',
        down,
      ],
      if (notchesX != 0) ...[
        'click',
        '--repeat',
        '${notchesX.abs()}',
        '--delay',
        '1',
        right,
      ],
    ];
  }

  String? _xdotoolChord(
    InputKey key,
    bool pressed,
    Set<KeyModifier> modifiers,
  ) {
    final name = XdotoolKeyNames.keys[key];
    if (name == null) {
      return null;
    }

    if (pressed) {
      _heldModifiers[key] = modifiers;
    }

    final held = switch (pressed) {
      true => modifiers,
      false => _heldModifiers.remove(key) ?? const <KeyModifier>{},
    };
    return [
      for (final modifier in KeyModifier.values)
        if (held.contains(modifier) && !_latched.contains(modifier))
          ?XdotoolKeyNames.modifiers[modifier],
      name,
    ].join('+');
  }

  List<String> _xdotoolLatch(Set<KeyModifier> held) {
    final previous = _latched;
    _latched = Set.unmodifiable(held);
    return [
      for (final modifier in KeyModifier.values.reversed)
        if (previous.contains(modifier) && !held.contains(modifier)) ...[
          'keyup',
          ?XdotoolKeyNames.modifiers[modifier],
        ],
      for (final modifier in KeyModifier.values)
        if (held.contains(modifier) && !previous.contains(modifier)) ...[
          'keydown',
          ?XdotoolKeyNames.modifiers[modifier],
        ],
    ];
  }

  String _xdotoolButton(PointerButton button) => switch (button) {
    .left => '1',
    .middle => '2',
    .right => '3',
  };

  /// ydotool runs one command per call; neighbouring keys share one.
  List<List<String>> _ydotool(List<InputAction> actions) {
    final runs = <List<String>>[];
    for (final action in actions) {
      switch (action) {
        case MoveAction(:final dx, :final dy):
          runs.add(['mousemove', '-x', '$dx', '-y', '$dy']);
        case ScrollAction(:final dx, :final dy):
          final (notchesX, notchesY) = _notches(dx, dy);
          if (notchesX != 0 || notchesY != 0) {
            runs.add([
              'mousemove',
              '-w',
              '-x',
              '$notchesX',
              '-y',
              '${-notchesY}',
            ]);
          }
        case ButtonAction(:final button, :final pressed):
          final flag = switch (pressed) {
            true => 0x40,
            false => 0x80,
          };
          final code = flag | button.code;
          runs.add(['click', '0x${code.toRadixString(16)}']);
        case KeyAction(:final key, :final pressed, :final modifiers):
          final code = LinuxKeyCodes.keys[key];
          if (code == null) {
            continue;
          }

          final raw = switch (pressed) {
            true => _chords.press(code, modifiers),
            false => _chords.release(code),
          };
          final keys = [
            for (final rawKey in raw)
              '${rawKey.code}:${_valueOf(rawKey.pressed)}',
          ];
          if (runs case [..., ['key', ...]]) {
            runs.last.addAll(keys);
            continue;
          }

          runs.add(['key', ...keys]);
        case TextAction(:final text):
          if (text.isNotEmpty) {
            runs.add(['type', '--', text]);
          }
        case ModifiersAction(:final held):
          final keys = [
            for (final rawKey in _chords.latch(held))
              '${rawKey.code}:${_valueOf(rawKey.pressed)}',
          ];
          if (keys.isNotEmpty) {
            runs.add(['key', ...keys]);
          }
      }
    }

    return runs;
  }

  /// Whole wheel notches for a scroll in pixels; the rest carries over.
  (int, int) _notches(int dx, int dy) {
    _scrollX += dx;
    _scrollY += dy;
    final notchesX = _scrollX ~/ pixelsPerNotch;
    final notchesY = _scrollY ~/ pixelsPerNotch;
    _scrollX -= notchesX * pixelsPerNotch;
    _scrollY -= notchesY * pixelsPerNotch;
    return (notchesX, notchesY);
  }

  int _valueOf(bool pressed) => switch (pressed) {
    true => 1,
    false => 0,
  };
}
