import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mirror_packets.dart';

const _idr = [0x65, 0x88, 0x84, 0x00, 0x33];
const _slice = [0x41, 0x9a, 0x24, 0x6c];
const _sei = [0x06, 0x05, 0x01, 0x80];

void main() {
  group('Avcc.parameterSets', () {
    test('finds the SPS and PPS of an avcC record', () {
      final sets = Avcc.parameterSets(avccRecord());

      expect(sets?.sps, sampleSps);
      expect(sets?.pps, samplePps);
    });

    test('takes the first SPS when there are several', () {
      final record = Uint8List.fromList([
        1, 0x64, 0x00, 0x1f, 0xff, 0xe2, //
        0, 2, 0x67, 0x01,
        0, 3, 0x67, 0x02, 0x03,
        1, 0, 2, 0x68, 0x09,
      ]);

      final sets = Avcc.parameterSets(record);

      expect(sets?.sps, [0x67, 0x01]);
      expect(sets?.pps, [0x68, 0x09]);
    });

    test('refuses records that are cut short or say nothing', () {
      final record = avccRecord();

      for (var length = 0; length < record.length; length++) {
        expect(Avcc.parameterSets(record.sublist(0, length)), isNull);
      }

      expect(Avcc.parameterSets(avccRecord()..[0] = 2), isNull);
      expect(Avcc.parameterSets(avccRecord()..[5] = 0xe0), isNull);
      expect(Avcc.parameterSets(avccRecord(sps: const [])), isNull);
    });

    test('tells an H.265 record apart', () {
      final hevc = Uint8List.fromList([0, 0, 0, 0x80, ...'hvc1'.codeUnits, 0]);

      expect(Avcc.isHevc(hevc), isTrue);
      expect(Avcc.isHevc(avccRecord()), isFalse);
    });
  });

  group('Avcc.toAnnexB', () {
    test('puts a start code where each length was', () {
      final unit = Avcc.toAnnexB(lengthPrefixed(const [_sei, _idr]));

      expect(unit?.data, annexB(const [_sei, _idr]));
      expect(unit?.keyframe, isTrue);
    });

    test('a picture without an IDR slice is not a keyframe', () {
      final unit = Avcc.toAnnexB(lengthPrefixed(const [_slice]));

      expect(unit?.data, annexB(const [_slice]));
      expect(unit?.keyframe, isFalse);
    });

    test('leaves the payload it was given untouched', () {
      final payload = lengthPrefixed(const [_slice]);

      Avcc.toAnnexB(payload);

      expect(payload, lengthPrefixed(const [_slice]));
    });

    test('refuses lengths that do not add up', () {
      final tooLong = lengthPrefixed(const [_slice])..[3] = 200;
      final trailing = Uint8List.fromList([
        ...lengthPrefixed(const [_slice]),
        0,
        0,
      ]);
      final empty = Uint8List.fromList(const [0, 0, 0, 0, 0x41]);

      expect(Avcc.toAnnexB(tooLong), isNull);
      expect(Avcc.toAnnexB(trailing), isNull);
      expect(Avcc.toAnnexB(empty), isNull);
      expect(Avcc.toAnnexB(Uint8List(0)), isNull);
    });

    test('refuses a unit whose first bit is set, as random bytes often do', () {
      expect(
        Avcc.toAnnexB(
          lengthPrefixed(const [
            [0xe5, 0x01],
          ]),
        ),
        isNull,
      );
    });
  });
}
