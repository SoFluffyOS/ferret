import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:protocol/mirroring.dart';

/// What both sides of `ferret.mirroring.v1` agree on.
abstract final class MirrorProtocol {
  /// The version of the messages this build speaks.
  static const version = 1;

  /// The source never sends a bigger picture than this.
  static const maxLongSide = 1920;
  static const maxShortSide = 1080;

  /// JPEG pictures are smaller and slower: each one is a whole image.
  static const jpegMaxLongSide = 1280;
  static const jpegMaxShortSide = 720;
  static const jpegFps = 10;

  static const minFps = 30;
  static const maxFps = 60;

  static const minBitrate = 2000000;
  static const maxBitrate = 8000000;
  static const startBitrate = 4000000;

  static Codec toProto(MirrorCodec codec) => switch (codec) {
    .h264 => .CODEC_H264,
    .jpeg => .CODEC_JPEG,
  };

  /// Null for a codec this build doesn't know.
  static MirrorCodec? fromProto(Codec codec) => switch (codec) {
    .CODEC_H264 => .h264,
    .CODEC_JPEG => .jpeg,
    _ => null,
  };

  /// The first of the viewer's [wanted] codecs the source [canEncode].
  static MirrorCodec? pick(
    Iterable<Codec> wanted,
    bool Function(MirrorCodec codec) canEncode,
  ) {
    for (final codec in wanted) {
      final known = fromProto(codec);
      if (known != null && canEncode(known)) {
        return known;
      }
    }

    return null;
  }

  /// The frame rate to capture at for a viewer asking for [wanted]
  /// (0 leaves it to the source).
  static int fpsFor(MirrorCodec codec, int wanted) {
    if (codec == .jpeg) {
      return jpegFps;
    }

    if (wanted == 0) {
      return maxFps;
    }

    return wanted.clamp(minFps, maxFps);
  }

  /// [limit] from a viewer (0 means none), never above the source's [most].
  static int sideFor(int limit, int most) {
    if (limit == 0) {
      return most;
    }

    return limit.clamp(1, most);
  }
}
