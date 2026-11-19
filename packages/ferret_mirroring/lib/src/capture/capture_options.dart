import 'package:ferret_mirroring/src/stream/mirror_audio.dart';
import 'package:ferret_mirroring/src/stream/mirror_codec.dart';

/// What this device can capture its screen with.
class CaptureSupport {
  const CaptureSupport({required this.h264, required this.jpeg});

  const CaptureSupport.none() : h264 = false, jpeg = false;

  final bool h264;
  final bool jpeg;

  bool get canCapture => h264 || jpeg;

  bool supports(MirrorCodec codec) => switch (codec) {
    .h264 => h264,
    .jpeg => jpeg,
  };
}

/// Whether this device can capture what it plays, to send along with its
/// screen.
enum AudioCaptureSupport {
  /// It can't: an Android older than 10, or not Android.
  unsupported,

  /// The system wants a permission first. Android calls it "record
  /// audio", though only what the device plays is captured, never its
  /// microphone.
  needsPermission,

  ready,
}

/// How the owner answered the system's screen capture prompt.
enum ConsentResult {
  granted,
  denied,

  /// Nobody answered in time, or the request was taken back.
  timedOut,

  /// The prompt couldn't be shown: the app is in the background and may
  /// not post notices.
  cannotAsk,

  /// The system refused to start capturing.
  failed,
}

/// The words on the notices the platform shows itself, in the owner's
/// language.
class ConsentTexts {
  const ConsentTexts({
    required this.askTitle,
    required this.askBody,
    required this.askChannelName,
    required this.sharingTitle,
    required this.sharingBody,
    required this.stopLabel,
    required this.sharingChannelName,
  });

  /// Such as "MacBook wants to see this screen".
  final String askTitle;
  final String askBody;
  final String askChannelName;

  /// The ongoing notice while sharing, such as "Sharing screen with
  /// MacBook".
  final String sharingTitle;
  final String sharingBody;
  final String stopLabel;
  final String sharingChannelName;
}

class CaptureOptions {
  const CaptureOptions({
    required this.codec,
    required this.maxLongSide,
    required this.maxShortSide,
    required this.fps,
    required this.bitrate,
    this.audioCodec,
  });

  final MirrorCodec codec;
  final int maxLongSide;
  final int maxShortSide;
  final int fps;

  /// Bits per second the video encoder starts with.
  final int bitrate;

  /// Capture what the device plays too, encoded this way. Null for
  /// pictures only.
  final MirrorAudioCodec? audioCodec;
}
