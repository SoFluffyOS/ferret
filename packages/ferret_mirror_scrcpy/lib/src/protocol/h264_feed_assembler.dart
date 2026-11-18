import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/protocol/annex_b.dart';
import 'package:ferret_mirror_scrcpy/src/protocol/h264_sps.dart';
import 'package:ferret_mirror_scrcpy/src/protocol/scrcpy_packet.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// Turns the encoder's packets into what a viewer wants: a
/// [FeedConfigured] for each new set of parameter sets, then one
/// [FeedFrame] per picture.
///
/// Android sends the parameter sets alone in a config packet. Like scrcpy's
/// own client, this puts them back in front of the next picture, so every
/// keyframe decodes on its own.
class H264FeedAssembler {
  H264FeedAssembler({this.fps = 0});

  final int fps;

  Uint8List? _pendingConfig;
  Uint8List? _sps;
  Uint8List? _pps;

  /// The events [packet] leads to. Throws a [FormatException] when a config
  /// packet has no usable parameter sets.
  List<FeedEvent> add(MediaPacket packet) {
    if (packet.isConfig) {
      return _configure(packet.data);
    }

    final config = _pendingConfig;
    _pendingConfig = null;
    final data = switch (config) {
      null => packet.data,
      final config => _joined(config, packet.data),
    };

    return [
      FeedFrame(
        MirrorFrame(
          data: data,
          ptsUs: packet.ptsUs,
          keyframe: packet.isKeyframe,
        ),
      ),
    ];
  }

  List<FeedEvent> _configure(Uint8List config) {
    final units = AnnexB.units(config);
    final sps = _first(units, AnnexB.sequenceParameterSet);
    final pps = _first(units, AnnexB.pictureParameterSet);
    if (sps == null || pps == null) {
      throw const FormatException('Config packet without SPS and PPS');
    }

    _pendingConfig = config;
    if (_same(sps, _sps) && _same(pps, _pps)) {
      return const [];
    }

    final parsed = H264Sps.parse(sps);
    _sps = sps;
    _pps = pps;
    return [
      FeedConfigured(
        MirrorStreamConfig(
          codec: .h264,
          width: parsed.width,
          height: parsed.height,
          fps: fps,
          sps: Uint8List.fromList(sps),
          pps: Uint8List.fromList(pps),
        ),
      ),
    ];
  }

  static Uint8List? _first(List<Uint8List> units, int type) {
    for (final unit in units) {
      if (AnnexB.typeOf(unit) == type) {
        return unit;
      }
    }

    return null;
  }

  static bool _same(Uint8List unit, Uint8List? known) {
    if (known == null || known.length != unit.length) {
      return false;
    }

    for (var index = 0; index < unit.length; index++) {
      if (unit[index] != known[index]) {
        return false;
      }
    }

    return true;
  }

  static Uint8List _joined(Uint8List config, Uint8List picture) {
    return Uint8List(config.length + picture.length)
      ..setRange(0, config.length, config)
      ..setRange(config.length, config.length + picture.length, picture);
  }
}
