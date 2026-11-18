import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('every key has a code on every platform', () {
    for (final key in InputKey.values) {
      test(key.name, () {
        expect(MacKeyCodes.keys[key], isNotNull, reason: 'macOS');
        expect(WindowsKeyCodes.keys[key], isNotNull, reason: 'Windows');
        expect(LinuxKeyCodes.keys[key], isNotNull, reason: 'Linux');
        expect(XdotoolKeyNames.keys[key], isNotNull, reason: 'xdotool');
      });
    }
  });

  test('every modifier has a code on every platform', () {
    for (final modifier in KeyModifier.values) {
      expect(MacKeyCodes.modifiers[modifier], isNotNull);
      expect(WindowsKeyCodes.modifiers[modifier], isNotNull);
      expect(LinuxKeyCodes.modifiers[modifier], isNotNull);
      expect(XdotoolKeyNames.modifiers[modifier], isNotNull);
    }
  });

  test('no two keys share a code', () {
    final mac = MacKeyCodes.keys.values
        .where((key) => !key.isMedia)
        .map((key) => key.code);
    expect(mac.toSet(), hasLength(mac.length));
    expect(
      WindowsKeyCodes.keys.values.toSet(),
      hasLength(WindowsKeyCodes.keys.length),
    );
    expect(
      LinuxKeyCodes.keys.values.toSet(),
      hasLength(LinuxKeyCodes.keys.length),
    );
  });

  test('the codes match the platform headers', () {
    expect(MacKeyCodes.keys[InputKey.enter], (code: 0x24, isMedia: false));
    expect(MacKeyCodes.keys[InputKey.a], (code: 0x00, isMedia: false));
    expect(MacKeyCodes.keys[InputKey.arrowUp], (code: 0x7E, isMedia: false));
    expect(MacKeyCodes.keys[InputKey.mediaPlayPause], (
      code: 16,
      isMedia: true,
    ));
    expect(WindowsKeyCodes.keys[InputKey.enter], 0x0D);
    expect(WindowsKeyCodes.keys[InputKey.z], 0x5A);
    expect(WindowsKeyCodes.keys[InputKey.f12], 0x7B);
    expect(WindowsKeyCodes.keys[InputKey.digit7], 0x37);
    expect(WindowsKeyCodes.keys[InputKey.mediaPlayPause], 0xB3);
    expect(LinuxKeyCodes.keys[InputKey.enter], 28);
    expect(LinuxKeyCodes.keys[InputKey.mediaPlayPause], 164);
    expect(XdotoolKeyNames.keys[InputKey.pageDown], 'Page_Down');
    expect(XdotoolKeyNames.keys[InputKey.f3], 'F3');
  });

  test('media keys are marked as media', () {
    for (final key in InputKey.values) {
      expect(MacKeyCodes.keys[key]?.isMedia, key.isMedia, reason: key.name);
    }
  });

  test('letters, digits and space map from characters', () {
    expect(InputKey.ofCharacter('c'), InputKey.c);
    expect(InputKey.ofCharacter('C'), InputKey.c);
    expect(InputKey.ofCharacter('4'), InputKey.digit4);
    expect(InputKey.ofCharacter(' '), InputKey.space);
    expect(InputKey.ofCharacter('é'), isNull);
    expect(InputKey.ofCharacter('ab'), isNull);
  });

  test('the US layout types ASCII with Shift where needed', () {
    expect(UsLayout.keyOf('a'), (code: 30, shift: false));
    expect(UsLayout.keyOf('A'), (code: 30, shift: true));
    expect(UsLayout.keyOf('!'), (code: 2, shift: true));
    expect(UsLayout.keyOf('?'), (code: LinuxKeyCodes.slash, shift: true));
    expect(UsLayout.keyOf('\n'), (code: 28, shift: false));
    expect(UsLayout.keyOf('é'), isNull);
  });
}
