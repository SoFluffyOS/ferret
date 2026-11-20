import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:protocol/mirroring.dart';

/// What both sides of `ferret.mirroring.v1` agree on.
abstract final class MirrorProtocol {
  /// The version of the messages this build speaks.
  static const version = 1;

  /// Flag in a device's feature support: it can show its screen.
  static const shareFlag = 'share';

  /// Flag in a device's feature support: it can show another's screen.
  static const viewFlag = 'view';

  /// Flag in a device's feature support: it can send its camera and
  /// microphone.
  static const cameraFlag = 'camera';

  /// What a camera sends unless the viewer asks for less: 720p at 30
  /// frames per second, light enough for an hour on a phone's battery.
  static const cameraLongSide = 1280;
  static const cameraShortSide = 720;
  static const cameraFps = 30;
  static const cameraMinBitrate = 800000;
  static const cameraMaxBitrate = 4000000;
  static const cameraStartBitrate = 2500000;

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

  static AudioCodec audioToProto(MirrorAudioCodec codec) => switch (codec) {
    .opus => .AUDIO_CODEC_OPUS,
    .pcm => .AUDIO_CODEC_PCM_S16LE,
  };

  /// Null for a codec this build doesn't know.
  static MirrorAudioCodec? audioFromProto(AudioCodec codec) => switch (codec) {
    .AUDIO_CODEC_OPUS => .opus,
    .AUDIO_CODEC_PCM_S16LE => .pcm,
    _ => null,
  };

  static CameraLens lensToProto(MirrorLens lens) => switch (lens) {
    .back => .CAMERA_LENS_BACK,
    .front => .CAMERA_LENS_FRONT,
  };

  /// Null for a lens this build doesn't know, or none said.
  static MirrorLens? lensFromProto(CameraLens lens) => switch (lens) {
    .CAMERA_LENS_BACK => .back,
    .CAMERA_LENS_FRONT => .front,
    _ => null,
  };

  /// The first of the viewer's [wanted] sound codecs this build knows.
  /// A phone encodes both.
  static MirrorAudioCodec? pickAudio(Iterable<AudioCodec> wanted) {
    for (final codec in wanted) {
      if (audioFromProto(codec) case final known?) {
        return known;
      }
    }

    return null;
  }

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
