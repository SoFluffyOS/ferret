import 'package:ferret_remote_input/src/held_input.dart';
import 'package:ferret_remote_input/src/injector_status.dart';
import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/input_injector.dart';
import 'package:ferret_remote_input/src/key_chords.dart';
import 'package:ferret_remote_input/src/keys/keys.dart';
import 'package:ferret_remote_input/src/messages.g.dart';

/// Injects through the native plugin: CGEvent on macOS, SendInput on
/// Windows. Key codes are mapped here, so the native side stays small.
class NativeInjector implements InputInjector {
  NativeInjector.macos({RemoteInputHostApi? api})
    : _api = api ?? RemoteInputHostApi(),
      _backend = .quartz,
      _chords = null;

  NativeInjector.windows({RemoteInputHostApi? api})
    : _api = api ?? RemoteInputHostApi(),
      _backend = .sendInput,
      _chords = KeyChords(WindowsKeyCodes.modifiers);

  final RemoteInputHostApi _api;
  final InjectorBackend _backend;

  /// Windows presses modifier keys itself; macOS sets them as event flags.
  final KeyChords? _chords;
  final HeldInput _held = HeldInput();

  /// macOS: the modifier keys held on their own, set as flags natively.
  Set<KeyModifier> _macLatched = const {};

  @override
  Future<InjectorStatus> status() async {
    try {
      return _statusOf(await _api.access());
    } on Object {
      return const .unavailable(.failed);
    }
  }

  @override
  Future<InjectorStatus> requestAccess() async {
    try {
      await _api.requestAccess();
      return _statusOf(await _api.access());
    } on Object {
      return const .unavailable(.failed);
    }
  }

  @override
  Future<void> openAccessSettings() => _api.openAccessSettings();

  @override
  Future<void> inject(List<InputAction> actions) async {
    final events = <NativeInputEvent>[];
    for (final action in actions) {
      final modifiers = switch (action) {
        KeyAction(:final key, pressed: false) => _held.modifiersOf(key),
        KeyAction(:final modifiers) => modifiers,
        _ => const <KeyModifier>{},
      };
      if (!_held.track(action)) {
        continue;
      }

      events.addAll(_eventsOf(action, modifiers));
    }

    if (events.isEmpty) {
      return;
    }

    await _api.inject(events);
  }

  @override
  Future<void> releaseAll() async {
    final releases = _held.releaseAll();
    final events = [
      for (final release in releases)
        ..._eventsOf(release, switch (release) {
          KeyAction(:final modifiers) => modifiers,
          _ => const <KeyModifier>{},
        }),
    ];
    _chords?.reset();
    _macLatched = const {};
    if (events.isNotEmpty) {
      await _api.inject(events);
    }

    await _api.releaseAll();
  }

  @override
  Future<void> dispose() => releaseAll();

  /// The native events for [action], public for tests of the mapping.
  List<NativeInputEvent> eventsOf(InputAction action) =>
      _eventsOf(action, switch (action) {
        KeyAction(:final modifiers) => modifiers,
        _ => const <KeyModifier>{},
      });

  List<NativeInputEvent> _eventsOf(
    InputAction action,
    Set<KeyModifier> modifiers,
  ) => switch (action) {
    MoveAction(:final dx, :final dy) => [_event(.move, x: dx, y: dy)],
    ScrollAction(:final dx, :final dy) => [_event(.scroll, x: dx, y: dy)],
    ButtonAction(:final button, :final pressed) => [
      _event(.button, code: button.code, pressed: pressed),
    ],
    KeyAction(:final key, :final pressed) => _keyEvents(
      key,
      pressed,
      modifiers,
    ),
    TextAction(:final text) => [
      if (text.isNotEmpty) _event(.text, text: text),
    ],
    ModifiersAction(:final held) => _latch(held),
  };

  /// Presses and releases of the modifier keys alone. macOS keeps them as
  /// flags on what follows, so each one carries the flags held after it.
  List<NativeInputEvent> _latch(Set<KeyModifier> held) {
    if (_chords case final chords?) {
      return [
        for (final rawKey in chords.latch(held))
          _event(.key, code: rawKey.code, pressed: rawKey.pressed),
      ];
    }

    final previous = _macLatched;
    _macLatched = Set.unmodifiable(held);
    final bits = KeyModifier.bitsOf(held);
    return [
      for (final modifier in KeyModifier.values.reversed)
        if (previous.contains(modifier) && !held.contains(modifier))
          _event(
            .key,
            code: MacKeyCodes.modifiers[modifier] ?? 0,
            modifiers: bits,
          ),
      for (final modifier in KeyModifier.values)
        if (held.contains(modifier) && !previous.contains(modifier))
          _event(
            .key,
            code: MacKeyCodes.modifiers[modifier] ?? 0,
            pressed: true,
            modifiers: bits,
          ),
    ];
  }

  List<NativeInputEvent> _keyEvents(
    InputKey key,
    bool pressed,
    Set<KeyModifier> modifiers,
  ) {
    if (_chords case final chords?) {
      final code = WindowsKeyCodes.keys[key];
      if (code == null) {
        return const [];
      }

      final raw = switch (pressed) {
        true => chords.press(code, modifiers),
        false => chords.release(code),
      };
      return [
        for (final rawKey in raw)
          _event(.key, code: rawKey.code, pressed: rawKey.pressed),
      ];
    }

    final macKey = MacKeyCodes.keys[key];
    if (macKey == null) {
      return const [];
    }

    final kind = switch (macKey.isMedia) {
      true => NativeEventKind.mediaKey,
      false => NativeEventKind.key,
    };
    return [
      _event(
        kind,
        code: macKey.code,
        pressed: pressed,
        modifiers: KeyModifier.bitsOf(modifiers),
      ),
    ];
  }

  InjectorStatus _statusOf(NativeAccess access) {
    if (access.granted) {
      return .ready(_backend);
    }

    if (access.needsPermission) {
      return .needsPermission(_backend);
    }

    return const .unavailable(.failed);
  }

  NativeInputEvent _event(
    NativeEventKind kind, {
    int x = 0,
    int y = 0,
    int code = 0,
    bool pressed = false,
    int modifiers = 0,
    String? text,
  }) => NativeInputEvent(
    kind: kind,
    x: x,
    y: y,
    code: code,
    pressed: pressed,
    modifiers: modifiers,
    text: text,
  );
}
