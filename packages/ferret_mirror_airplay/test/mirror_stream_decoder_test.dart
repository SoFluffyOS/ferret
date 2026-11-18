import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mirror_packets.dart';

final _key = Uint8List.fromList(List.generate(16, (index) => index));
final _iv = Uint8List.fromList(List.generate(16, (index) => 0xf0 + index));
const _idr = [0x65, 0x88, 0x84, 0x00, 0x33, 0xff, 0xfe];
const _slice = [0x41, 0x9a, 0x24, 0x6c, 0x41];

MirrorPacket _packet(Uint8List bytes) => MirrorPacketReader().add(bytes).single;

MirrorPacket _codec({
  int option = 0x0116,
  int width = 886,
  int height = 1920,
  List<int> sps = sampleSps,
}) => _packet(
  mirrorPacket(
    type: 1,
    payload: avccRecord(sps: sps),
    option: option,
    width: width,
    height: height,
    sourceWidth: 1170,
    sourceHeight: 2532,
  ),
);

void main() {
  late AesCtrStream phone;
  late MirrorStreamDecoder decoder;

  MirrorPacket video(List<List<int>> units, {int timestamp = 0}) => _packet(
    mirrorPacket(
      type: 0,
      payload: phone.process(lengthPrefixed(units)),
      timestamp: timestamp,
    ),
  );

  setUp(() {
    phone = AesCtrStream(_key, _iv);
    decoder = MirrorStreamDecoder(key: _key, iv: _iv);
  });

  test('the codec packet configures the feed with size and parameter sets', () {
    final events = decoder.add(_codec());

    final config = (events.single as FeedConfigured).config;
    expect(config.codec, MirrorCodec.h264);
    expect((config.width, config.height), (886, 1920));
    expect(config.sps, sampleSps);
    expect(config.pps, samplePps);
  });

  test('falls back to the screen size when the picture size is missing', () {
    final events = decoder.add(_codec(width: 0, height: 0));

    final config = (events.single as FeedConfigured).config;
    expect((config.width, config.height), (1170, 2532));
  });

  test('video packets are decrypted in order into Annex-B frames', () {
    decoder.add(_codec());

    final first = decoder.add(video(const [_idr], timestamp: 3 << 32)).single;
    final second = decoder
        .add(video(const [_slice], timestamp: 4 << 32))
        .single;

    final keyframe = (first as FeedFrame).frame;
    expect(keyframe.data, annexB(const [_idr]));
    expect(keyframe.keyframe, isTrue);
    expect(keyframe.ptsUs, 3000000);
    final next = (second as FeedFrame).frame;
    expect(next.data, annexB(const [_slice]));
    expect(next.keyframe, isFalse);
    expect(next.ptsUs, 4000000);
  });

  test('pictures before the codec packet are skipped but still decrypted', () {
    expect(decoder.add(video(const [_slice])), isEmpty);
    decoder.add(_codec());

    final event = decoder.add(video(const [_idr])).single;

    expect((event as FeedFrame).frame.data, annexB(const [_idr]));
  });

  test('the same codec packet again changes nothing', () {
    decoder.add(_codec());

    expect(decoder.add(_codec()), isEmpty);
  });

  test('a new size configures again, as when the phone is rotated', () {
    decoder.add(_codec());

    final events = decoder.add(_codec(width: 1920, height: 886));

    final config = (events.single as FeedConfigured).config;
    expect((config.width, config.height), (1920, 886));
  });

  test('says when the phone\'s screen goes off and comes back', () {
    decoder.add(_codec());

    final off = decoder.add(_codec(option: 0x0156));
    final on = decoder.add(_codec(option: 0x0116));

    expect((off.single as FeedSourceState).screenOff, isTrue);
    expect((on.single as FeedSourceState).screenOff, isFalse);
  });

  test('an H.265 or empty codec packet ends the feed with no codec', () {
    final hevc = _packet(
      mirrorPacket(type: 1, payload: [0, 0, 0, 0x80, ...'hvc1'.codeUnits, 0]),
    );
    final empty = _packet(mirrorPacket(type: 1, payload: const []));

    expect((decoder.add(hevc).single as FeedEnded).reason, FeedEnd.noCodec);
    expect((decoder.add(empty).single as FeedEnded).reason, FeedEnd.noCodec);
  });

  test('a codec packet that cannot be read ends the feed', () {
    final broken = _packet(mirrorPacket(type: 1, payload: const [1, 2, 3]));

    expect((decoder.add(broken).single as FeedEnded).reason, FeedEnd.failed);
  });

  test('a wrong key ends the feed after a run of unreadable pictures', () {
    final wrong = MirrorStreamDecoder(
      key: Uint8List.fromList(List.filled(16, 9)),
      iv: _iv,
    )..add(_codec());
    final events = <FeedEvent>[];

    for (var count = 0; count < MirrorStreamDecoder.maxBadFrames; count++) {
      events.addAll(wrong.add(video(const [_idr, _slice])));
    }

    expect((events.single as FeedEnded).reason, FeedEnd.failed);
  });

  test('heartbeats and reports are ignored', () {
    decoder.add(_codec());

    expect(
      decoder.add(_packet(mirrorPacket(type: 2, payload: const []))),
      isEmpty,
    );
    expect(
      decoder.add(_packet(mirrorPacket(type: 5, payload: List.filled(40, 1)))),
      isEmpty,
    );
  });
}
