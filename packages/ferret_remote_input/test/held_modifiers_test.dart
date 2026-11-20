import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'native_injector_test.dart' show FakeHostApi;

void main() {
  const codes = {
    KeyModifier.shift: 1,
    KeyModifier.control: 2,
    KeyModifier.alt: 3,
    KeyModifier.meta: 4,
  };

  group('chords', () {
    test('latched modifiers go down once and up when let go', () {
      final chords = KeyChords(codes);

      expect(chords.latch({.shift, .meta}), [
        (code: 1, pressed: true),
        (code: 4, pressed: true),
      ]);
      expect(chords.latch({.meta}), [(code: 1, pressed: false)]);
      expect(chords.latch({}), [(code: 4, pressed: false)]);
      expect(chords.latch({}), isEmpty);
    });

    test('a key never presses or lets go of a latched modifier', () {
      final chords = KeyChords(codes)..latch({.control});

      expect(chords.press(50, {.control}), [(code: 50, pressed: true)]);
      expect(chords.release(50), [(code: 50, pressed: false)]);
    });

    test('a modifier a key pressed stays down while it is latched', () {
      final chords = KeyChords(codes);
      chords.press(50, {.shift});

      expect(chords.latch({.shift}), isEmpty);
      expect(chords.release(50), [(code: 50, pressed: false)]);
      expect(chords.latch({}), [(code: 1, pressed: false)]);
    });

    test('a repeated key keeps the modifiers it pressed first', () {
      final chords = KeyChords(codes)..press(50, {.control});

      expect(chords.press(50, {.control}), [(code: 50, pressed: true)]);
      expect(chords.release(50), [
        (code: 50, pressed: false),
        (code: 2, pressed: false),
      ]);
    });
  });

  test('held input lets go of latched modifiers last', () {
    final held = HeldInput()
      ..track(const ModifiersAction({.shift}))
      ..track(const ButtonAction(.left, pressed: true));

    expect(held.track(const ModifiersAction({.shift})), isFalse);
    expect(held.modifiers, {KeyModifier.shift});
    expect(held.releaseAll(), const [
      ButtonAction(.left, pressed: false),
      ModifiersAction({}),
    ]);
    expect(held.isEmpty, isTrue);
  });

  test('macOS holds modifiers as flags-carrying key events', () async {
    final api = FakeHostApi();
    final injector = NativeInjector.macos(api: api);

    await injector.inject(const [
      ModifiersAction({.shift}),
      ButtonAction(.left, pressed: true),
      ButtonAction(.left, pressed: false),
    ]);
    await injector.releaseAll();

    final keys = [
      for (final event in api.events)
        if (event.kind == NativeEventKind.key)
          (event.code, event.pressed, event.modifiers),
    ];
    expect(keys, [(0x38, true, 1), (0x38, false, 0)]);
  });

  test('Windows presses the modifier keys themselves', () async {
    final api = FakeHostApi();
    final injector = NativeInjector.windows(api: api);

    await injector.inject(const [
      ModifiersAction({.control}),
      KeyAction(.c, pressed: true, modifiers: {.control}),
      KeyAction(.c, pressed: false),
    ]);
    await injector.releaseAll();

    expect(
      [for (final event in api.events) (event.code, event.pressed)],
      [(0x11, true), (0x43, true), (0x43, false), (0x11, false)],
    );
  });

  group('Linux commands', () {
    test('xdotool holds modifiers with keydown and leaves them out of '
        'chords', () {
      final injector = CommandInjector(.xdotool);

      expect(
        injector.commandsOf(const [
          ModifiersAction({.control}),
          KeyAction(.c, pressed: true, modifiers: {.control}),
          KeyAction(.c, pressed: false),
          ModifiersAction({}),
        ]),
        [
          ['keydown', 'ctrl', 'keydown', 'c', 'keyup', 'c', 'keyup', 'ctrl'],
        ],
      );
    });

    test('ydotool presses raw modifier codes', () {
      final injector = CommandInjector(.ydotool);

      expect(
        injector.commandsOf(const [
          ModifiersAction({.shift}),
          ModifiersAction({}),
        ]),
        [
          ['key', '42:1'],
          ['key', '42:0'],
        ],
      );
    });
  });
}
