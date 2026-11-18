import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bytes.dart';

void main() {
  group('AnnexB', () {
    test('splits units on 3 and 4 byte start codes', () {
      final units = AnnexB.units(
        hex('00000001 6742 000001 68ce 00000001 65b8'),
      );

      expect(units, [hex('6742'), hex('68ce'), hex('65b8')]);
      expect(units.map(AnnexB.typeOf), [7, 8, 5]);
    });

    test('finds nothing without a start code', () {
      expect(AnnexB.units(hex('6742c029')), isEmpty);
    });

    test('takes emulation prevention bytes out of a payload', () {
      expect(
        AnnexB.payload(hex('67 000003 01 000003 00')),
        hex('0000 01 0000 00'),
      );
    });
  });

  group('H264Sps', () {
    test('reads the size of the emulator\'s baseline stream', () {
      final sps = H264Sps.parse(emulatorSps);

      expect(sps.profile, 66);
      expect(sps.level, 41);
      expect((sps.width, sps.height), (576, 1280));
    });

    test('reads a cropped high profile 1080p stream', () {
      final sps = H264Sps.parse(
        hex(
          '6764 0028 acd9 4078 0227 e5c0 4400 0003 0004 0000 0300 f03c 60c6 58',
        ),
      );

      expect(sps.profile, 100);
      expect((sps.width, sps.height), (1920, 1080));
    });

    test('refuses a unit that is not an SPS', () {
      expect(() => H264Sps.parse(emulatorPps), throwsFormatException);
      expect(() => H264Sps.parse(Uint8List(0)), throwsFormatException);
    });

    test('refuses an SPS cut short', () {
      expect(
        () => H264Sps.parse(emulatorSps.sublist(0, 6)),
        throwsFormatException,
      );
    });
  });

  group('H264FeedAssembler', () {
    final configData = hex(
      '000000016742c0298d680900a1a420202020f08846a00000000168ce01a835c8',
    );
    final config = MediaPacket(
      data: configData,
      ptsUs: 0,
      isConfig: true,
      isKeyframe: false,
    );
    final picture = hex('0000000165b80004');

    MediaPacket keyframe(int ptsUs) => MediaPacket(
      data: picture,
      ptsUs: ptsUs,
      isConfig: false,
      isKeyframe: true,
    );

    test('turns a config packet into the stream\'s config', () {
      final events = H264FeedAssembler(fps: 30).add(config);

      final configured = (events.single as FeedConfigured).config;
      expect(configured.codec, MirrorCodec.h264);
      expect((configured.width, configured.height), (576, 1280));
      expect(configured.fps, 30);
      expect(configured.sps, emulatorSps);
      expect(configured.pps, emulatorPps);
    });

    test('puts the parameter sets in front of the next keyframe only', () {
      final assembler = H264FeedAssembler()..add(config);

      final first = (assembler.add(keyframe(100)).single as FeedFrame).frame;
      final second = (assembler.add(keyframe(200)).single as FeedFrame).frame;

      expect(first.data, joined([configData, picture]));
      expect(first.keyframe, isTrue);
      expect(first.ptsUs, 100);
      expect(AnnexB.units(first.data).map(AnnexB.typeOf), [7, 8, 5]);
      expect(second.data, picture);
    });

    test('stays quiet when the same config comes again', () {
      final assembler = H264FeedAssembler()..add(config);

      expect(assembler.add(config), isEmpty);
    });

    test('configures again when the size changes', () {
      final assembler = H264FeedAssembler()..add(config);
      final rotated = MediaPacket(
        data: hex(
          '00000001 6764 0028 acd9 4078 0227 e5c0 4400 0003 0004 0000 0300 '
          'f03c 60c6 58 00000001 68ce 3c80',
        ),
        ptsUs: 0,
        isConfig: true,
        isKeyframe: false,
      );

      final configured =
          (assembler.add(rotated).single as FeedConfigured).config;

      expect((configured.width, configured.height), (1920, 1080));
    });

    test('refuses a config packet without parameter sets', () {
      final broken = MediaPacket(
        data: hex('0000000165b8'),
        ptsUs: 0,
        isConfig: true,
        isKeyframe: false,
      );

      expect(() => H264FeedAssembler().add(broken), throwsFormatException);
    });
  });
}
