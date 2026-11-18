import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hex.dart';

/// Written by macOS's own `plutil -convert binary1`, so the decoder is
/// checked against Apple's encoder and not only against ours.
const _appleFixture = '''
62706c6973743030dc0102030405060708090a0b0c0d0e0f10111213141516172a536569765f1012
73747265616d436f6e6e656374696f6e4944546c6f6e67536269675f1018697353637265656e4d69
72726f72696e6753657373696f6e547768656e55726174696f5a74696d696e67506f7274536f6666
556d6f64656c5773747265616d73546e616d654f1010000102030405060708090a0b0c0d0e0f1386
5aedeff40181165f101a6162636465666768696a6b6c6d6e6f707172737475767778797a13000000
0100000000093341c856d750000000233fe000000000000011d431085a6950686f6e6531342c32af
1010181b1c1d1e1f20212223242526272829d1191a5474797065106e100110021003100410051006
100710081009100a100b100c100d100e100f6e00530069006d006f006e2019007300200069005000
68006f006e0065000800210025003a003f0043005e0063006900740078007e0086008b009e00a700
c400cd00ce00d700e000e300e400ef01020105010a010c010e01100112011401160118011a011c01
1e01200122012401260128012a0000000000000201000000000000002b0000000000000000000000
0000000147
''';

void main() {
  group('BinaryPlistDecoder', () {
    test('reads every type from a plist written by plutil', () {
      final dict = BinaryPlistDecoder.decodeDict(unhex(_appleFixture));

      expect(dict['name'], 'Simon’s iPhone');
      expect(dict['model'], 'iPhone14,2');
      expect(dict['timingPort'], 54321);
      expect(dict['streamConnectionID'], -8765432109876543210);
      expect(dict['big'], 4294967296);
      expect(dict['ratio'], 0.5);
      expect(dict['isScreenMirroringSession'], true);
      expect(dict['off'], false);
      expect(dict['eiv'], Uint8List.fromList(List.generate(16, (i) => i)));
      expect(dict['when'], DateTime.utc(2026, 11, 18, 10));
      expect(dict['long'], 'abcdefghijklmnopqrstuvwxyz');
      expect(dict['streams'], [
        {'type': 110},
        ...List.generate(15, (index) => index + 1),
      ]);
    });

    test('refuses bytes that are not a plist', () {
      expect(
        () => BinaryPlistDecoder.decode(Uint8List(64)),
        throwsFormatException,
      );
      expect(
        () =>
            BinaryPlistDecoder.decode(Uint8List.fromList('bplist00'.codeUnits)),
        throwsFormatException,
      );
      expect(BinaryPlistDecoder.decodeDict(Uint8List(3)), isEmpty);
    });

    test('refuses every truncation of a valid plist without crashing', () {
      final bytes = unhex(_appleFixture);
      for (var length = 0; length < bytes.length; length++) {
        expect(
          BinaryPlistDecoder.decodeDict(bytes.sublist(0, length)),
          isA<Map<String, Object?>>(),
        );
      }
    });

    test('survives every single corrupted byte', () {
      final bytes = unhex(_appleFixture);
      for (var index = 0; index < bytes.length; index++) {
        final corrupted = Uint8List.fromList(bytes)..[index] ^= 0xff;
        expect(
          BinaryPlistDecoder.decodeDict(corrupted),
          isA<Map<String, Object?>>(),
        );
      }
    });

    test('refuses an array that holds itself', () {
      final looped = Uint8List.fromList([
        ...'bplist00'.codeUnits,
        0xa1, 0x00, // an array whose one item is object 0, itself
        0x08, // offset table: object 0 at byte 8
        0, 0, 0, 0, 0, 0, 1, 1,
        0, 0, 0, 0, 0, 0, 0, 1,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 10,
      ]);

      expect(() => BinaryPlistDecoder.decode(looped), throwsFormatException);
    });
  });

  group('BinaryPlistEncoder', () {
    test('writes what the decoder reads back', () {
      final value = {
        'name': 'Ferret',
        'unicode': 'Tiếng Việt 🦊',
        'features': 0x5A7FFEE6,
        'small': 7,
        'port': 54321,
        'negative': -3,
        'wide': 0x123456789abcdef,
        'ratio': 1 / 60,
        'yes': true,
        'no': false,
        'nothing': null,
        'pk': Uint8List.fromList(List.generate(32, (index) => 255 - index)),
        'when': DateTime.utc(2026, 11, 18, 10, 30),
        'long': 'x' * 300,
        'displays': [
          {'width': 1920, 'height': 1080, 'rotation': false},
        ],
        'many': List.generate(40, (index) => 'item $index'),
      };

      expect(
        BinaryPlistDecoder.decode(BinaryPlistEncoder.encode(value)),
        value,
      );
    });

    test('starts with the magic and ends with a 32-byte trailer', () {
      final bytes = BinaryPlistEncoder.encode({'a': 1});

      expect(String.fromCharCodes(bytes.sublist(0, 8)), 'bplist00');
      expect(
        hex(bytes),
        endsWith(
          '0000000000000003'
          '0000000000000000'
          '000000000000000f',
        ),
      );
    });

    test('refuses values a plist cannot hold', () {
      expect(
        () => BinaryPlistEncoder.encode({'when': const Duration(seconds: 1)}),
        throwsArgumentError,
      );
    });
  });
}
