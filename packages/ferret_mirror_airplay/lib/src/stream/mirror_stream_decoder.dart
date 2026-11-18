import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/crypto/crypto.dart';
import 'package:ferret_mirror_airplay/src/stream/avcc.dart';
import 'package:ferret_mirror_airplay/src/stream/mirror_packet.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// Turns the packets of one mirroring stream into feed events: the codec
/// packet becomes a [FeedConfigured], each video packet is decrypted and
/// becomes a [FeedFrame].
class MirrorStreamDecoder {
  MirrorStreamDecoder({required Uint8List key, required Uint8List iv})
    : _cipher = AesCtrStream(key, iv);

  /// This many pictures in a row that make no sense after decryption
  /// means the key is wrong, not that one packet was damaged.
  static const maxBadFrames = 30;
  static const _pausedBit = 0x40;

  final AesCtrStream _cipher;
  MirrorStreamConfig? _config;
  bool _screenOff = false;
  int _badFrames = 0;
  int _lost = 0;

  List<FeedEvent> add(MirrorPacket packet) => switch (packet.header.type) {
    .codec => _onCodec(packet),
    .video => _onVideo(packet),
    .heartbeat || .other => const [],
  };

  List<FeedEvent> _onCodec(MirrorPacket packet) {
    final header = packet.header;
    if (packet.payload.isEmpty || Avcc.isHevc(packet.payload)) {
      return const [FeedEnded(.noCodec, detail: 'The phone sent H.265')];
    }

    final sets = Avcc.parameterSets(packet.payload);
    if (sets == null) {
      return const [FeedEnded(.failed, detail: 'Unreadable avcC record')];
    }

    final events = <FeedEvent>[];
    final screenOff = header.option & _pausedBit != 0;
    if (screenOff != _screenOff) {
      _screenOff = screenOff;
      events.add(FeedSourceState(screenOff: screenOff));
    }

    final config = MirrorStreamConfig(
      codec: .h264,
      width: _firstSet(header.width, header.sourceWidth),
      height: _firstSet(header.height, header.sourceHeight),
      sps: Uint8List.fromList(sets.sps),
      pps: Uint8List.fromList(sets.pps),
    );
    if (_sameAsCurrent(config)) {
      return events;
    }

    _config = config;
    events.add(FeedConfigured(config));
    return events;
  }

  /// Every video payload is decrypted, shown or not: the key stream runs
  /// over all of them in order.
  List<FeedEvent> _onVideo(MirrorPacket packet) {
    final clear = _cipher.process(packet.payload);
    if (_config == null) {
      return const [];
    }

    final unit = Avcc.toAnnexB(clear);
    if (unit == null) {
      _badFrames++;
      _lost++;
      if (_badFrames == maxBadFrames) {
        return const [
          FeedEnded(.failed, detail: 'The video could not be decrypted'),
        ];
      }

      return const [];
    }

    final lost = _lost;
    _badFrames = 0;
    _lost = 0;
    return [
      FeedFrame(
        MirrorFrame(
          data: unit.data,
          ptsUs: packet.header.timestampUs,
          keyframe: unit.keyframe,
        ),
        lost: lost,
      ),
    ];
  }

  int _firstSet(int first, int second) {
    if (first > 0) {
      return first;
    }

    return second;
  }

  bool _sameAsCurrent(MirrorStreamConfig config) {
    final current = _config;
    return current != null &&
        current.width == config.width &&
        current.height == config.height &&
        _sameBytes(current.sps, config.sps) &&
        _sameBytes(current.pps, config.pps);
  }

  bool _sameBytes(Uint8List? first, Uint8List? second) {
    if (first == null || second == null || first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
