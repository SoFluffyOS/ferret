import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

/// How a key press on this computer becomes input for the phone.
void main() {
  const all = <ControlAbility>{.pointer, .keys, .text, .buttons, .clipboard};
  const keysOnly = <ControlAbility>{.pointer, .keys, .buttons};

  KeyDownEvent down(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical, {
    String? character,
  }) => KeyDownEvent(
    physicalKey: physical,
    logicalKey: logical,
    character: character,
    timeStamp: Duration.zero,
  );

  KeyUpEvent up(PhysicalKeyboardKey physical, LogicalKeyboardKey logical) =>
      KeyUpEvent(
        physicalKey: physical,
        logicalKey: logical,
        timeStamp: Duration.zero,
      );

  InputAction? act(
    KeyEvent event, {
    Set<KeyModifier> modifiers = const {},
    Set<ControlAbility> abilities = all,
    KeyModifier shortcut = .meta,
  }) => MirrorKeys.actionOf(
    event,
    modifiers: modifiers,
    abilities: abilities,
    shortcut: shortcut,
  );

  group('typing', () {
    test('a letter goes as text, so the keyboard layout holds', () {
      final action = act(
        down(.keyQ, .keyA, character: 'a'),
      );

      expect((action as SendText).text, 'a');
    });

    test('a capital and a symbol go as the character they make', () {
      final capital = act(
        down(.keyA, .keyA, character: 'A'),
        modifiers: const {.shift},
      );
      final symbol = act(down(.digit1, .exclamation, character: '!'));

      expect((capital as SendText).text, 'A');
      expect((symbol as SendText).text, '!');
    });

    test('an accent or an emoji goes through the phone\'s clipboard', () {
      final accent = act(down(.keyE, .keyE, character: 'é'));
      final emoji = act(down(.keyF, .keyF, character: '🦊'));

      expect((accent as PasteText).text, 'é');
      expect((emoji as PasteText).text, '🦊');
    });

    test('without a clipboard on that way, it is typed as it is', () {
      final action = act(
        down(.keyE, .keyE, character: 'é'),
        abilities: const {.keys, .text},
      );

      expect((action as SendText).text, 'é');
    });

    test('Enter, Backspace, Tab and the arrows go as keys', () {
      for (final (physical, logical, character, usage) in [
        (PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter, '\n', 0x28),
        (
          PhysicalKeyboardKey.backspace,
          LogicalKeyboardKey.backspace,
          null,
          0x2A,
        ),
        (PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab, '\t', 0x2B),
        (
          PhysicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
          null,
          0x50,
        ),
      ]) {
        final action = act(down(physical, logical, character: character));

        expect((action as SendKey).key.usage, usage);
        expect(action.key.phase, KeyPhase.down);
      }
    });

    test('a way that only takes keys gets every press as a key', () {
      final action = act(
        down(.keyA, .keyA, character: 'a'),
        abilities: keysOnly,
      );

      expect((action as SendKey).key.usage, 0x04);
    });

    test('a key held down repeats', () {
      final action = act(
        const KeyRepeatEvent(
          physicalKey: .backspace,
          logicalKey: .backspace,
          timeStamp: Duration.zero,
        ),
      );

      expect((action as SendKey).key.repeat, 1);
    });

    test('a key that isn\'t on a keyboard is left to this computer', () {
      final action = act(
        down(.mediaPlayPause, .mediaPlayPause),
        abilities: keysOnly,
      );

      expect(action, isNull);
    });
  });

  group('Escape', () {
    test('is the phone\'s Back, once per press', () {
      expect(
        (act(down(.escape, .escape)) as PressButton).button,
        DeviceButton.back,
      );
      expect(act(up(.escape, .escape)), isA<NoInput>());
    });
  });

  group('this computer\'s shortcut key', () {
    const meta = <KeyModifier>{.meta};

    test('V pastes this computer\'s clipboard on the phone', () {
      expect(
        act(down(.keyV, .keyV, character: 'v'), modifiers: meta),
        isA<PasteClipboard>(),
      );
      expect(act(up(.keyV, .keyV), modifiers: meta), isA<NoInput>());
    });

    test('1 is Home, 2 is Recents, [ is Back, R rotates', () {
      for (final (physical, logical, button) in [
        (
          PhysicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit1,
          DeviceButton.home,
        ),
        (
          PhysicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit2,
          DeviceButton.recents,
        ),
        (
          PhysicalKeyboardKey.bracketLeft,
          LogicalKeyboardKey.bracketLeft,
          DeviceButton.back,
        ),
        (
          PhysicalKeyboardKey.keyR,
          LogicalKeyboardKey.keyR,
          DeviceButton.rotate,
        ),
      ]) {
        final action = act(down(physical, logical), modifiers: meta);

        expect((action as PressButton).button, button);
      }
    });

    test('K opens the field for composed text', () {
      expect(
        act(down(.keyK, .keyK, character: 'k'), modifiers: meta),
        isA<OpenTextField>(),
      );
    });

    test('C, X, A and Z reach the phone as its Control shortcuts', () {
      for (final (physical, logical, usage) in [
        (PhysicalKeyboardKey.keyC, LogicalKeyboardKey.keyC, 0x06),
        (PhysicalKeyboardKey.keyX, LogicalKeyboardKey.keyX, 0x1B),
        (PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA, 0x04),
        (PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ, 0x1D),
      ]) {
        final action = act(down(physical, logical), modifiers: meta);

        expect((action as SendKey).key.usage, usage);
        expect(action.key.modifiers, const {KeyModifier.control});
      }
    });

    test('W, Q, M and the size keys stay with this computer\'s window', () {
      for (final (physical, logical) in [
        (PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW),
        (PhysicalKeyboardKey.keyQ, LogicalKeyboardKey.keyQ),
        (PhysicalKeyboardKey.keyM, LogicalKeyboardKey.keyM),
        (PhysicalKeyboardKey.digit0, LogicalKeyboardKey.digit0),
        (PhysicalKeyboardKey.equal, LogicalKeyboardKey.equal),
        (PhysicalKeyboardKey.minus, LogicalKeyboardKey.minus),
      ]) {
        expect(act(down(physical, logical), modifiers: meta), isNull);
      }
    });

    test('with another modifier too, the shortcut is this computer\'s', () {
      final action = act(
        down(.keyA, .keyA),
        modifiers: const {.meta, .shift},
      );

      expect(action, isNull);
    });

    test('with Shift, S takes a screenshot, even of a device that is view '
        'only', () {
      final pressed = act(
        down(.keyS, .keyS),
        modifiers: const {.meta, .shift},
        abilities: const {},
      );
      final released = act(
        up(.keyS, .keyS),
        modifiers: const {.meta, .shift},
        abilities: const {},
      );

      expect(pressed, isA<TakeScreenshot>());
      expect(released, isA<NoInput>());
    });

    test('is Control on a computer that isn\'t a Mac', () {
      final paste = act(
        down(.keyV, .keyV, character: 'v'),
        modifiers: const {.control},
        shortcut: .control,
      );
      final metaV = act(
        down(.keyV, .keyV),
        modifiers: const {.meta},
        shortcut: .control,
      );

      expect(paste, isA<PasteClipboard>());
      expect((metaV as SendKey).key.modifiers, const {KeyModifier.meta});
    });

    test('a view-only-by-keys way gets no paste and no buttons', () {
      final paste = act(
        down(.keyV, .keyV),
        modifiers: meta,
        abilities: const {.keys},
      );
      final home = act(
        down(.digit1, .digit1),
        modifiers: meta,
        abilities: const {.keys},
      );

      expect((paste as SendKey).key.modifiers, const {KeyModifier.control});
      expect(home, isA<SendKey>());
    });
  });

  group('composed text', () {
    test('plain text is typed; anything else is pasted', () {
      expect(MirrorKeys.textAction('hello world', all), isA<SendText>());
      expect(MirrorKeys.textAction('señor 你好', all), isA<PasteText>());
    });
  });

  group('a computer\'s display', () {
    const computer = <ControlAbility>{.pointer, .keys, .text, .mouse};

    test('shortcuts go as they are, Command and all', () {
      final action = act(
        down(PhysicalKeyboardKey.keyC, LogicalKeyboardKey.keyC, character: 'c'),
        modifiers: const {.meta},
        abilities: computer,
      );

      final key = (action as SendKey).key;
      expect(key.usage, 0x06);
      expect(key.modifiers, {KeyModifier.meta});
    });

    test('Command-Q stays with this Mac', () {
      final action = act(
        down(PhysicalKeyboardKey.keyQ, LogicalKeyboardKey.keyQ, character: 'q'),
        modifiers: const {.meta},
        abilities: computer,
      );

      expect(action, isNull);
    });

    test('typing still types', () {
      final action = act(
        down(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA, character: 'a'),
        abilities: computer,
      );

      expect((action as SendText).text, 'a');
    });
  });
}
