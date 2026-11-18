import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codes = {
    KeyModifier.shift: 1,
    KeyModifier.control: 2,
    KeyModifier.alt: 3,
    KeyModifier.meta: 4,
  };

  test('modifiers go down before the key and up after it', () {
    final chords = KeyChords(codes);

    expect(chords.press(50, {.control, .shift}), [
      (code: 1, pressed: true),
      (code: 2, pressed: true),
      (code: 50, pressed: true),
    ]);
    expect(chords.release(50), [
      (code: 50, pressed: false),
      (code: 2, pressed: false),
      (code: 1, pressed: false),
    ]);
  });

  test('a modifier already down for another key is not pressed twice', () {
    final chords = KeyChords(codes);
    chords.press(50, {.control});

    expect(chords.press(51, {.control}), [(code: 51, pressed: true)]);
    expect(chords.release(51), [(code: 51, pressed: false)]);
    expect(chords.release(50), [
      (code: 50, pressed: false),
      (code: 2, pressed: false),
    ]);
  });

  test('a release of a key that was never pressed releases only it', () {
    expect(KeyChords(codes).release(9), [(code: 9, pressed: false)]);
  });

  test('held input lets go of everything once', () {
    final held = HeldInput()
      ..track(const ButtonAction(.left, pressed: true))
      ..track(const KeyAction(.a, pressed: true, modifiers: {.meta}));

    expect(held.track(const ButtonAction(.right, pressed: false)), isFalse);
    expect(held.releaseAll(), [
      const ButtonAction(.left, pressed: false),
      const KeyAction(.a, pressed: false, modifiers: {.meta}),
    ]);
    expect(held.isEmpty, isTrue);
    expect(held.releaseAll(), isEmpty);
  });
}
