import 'package:ferret_mirroring/src/stream/mirror_audio.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';

/// How a capture ended without this side asking for it.
enum CaptureEnd {
  /// Stop on the ongoing notice.
  stoppedByUser,

  /// The system ended it, such as when the phone was locked.
  endedBySystem,

  failed,
}

/// Something a running capture reports.
sealed class CaptureEvent {
  const CaptureEvent();
}

class CaptureConfigured extends CaptureEvent {
  const CaptureConfigured(this.config);

  final MirrorStreamConfig config;
}

class CaptureFrame extends CaptureEvent {
  const CaptureFrame(this.frame);

  final MirrorFrame frame;
}

/// Sound follows, encoded this way.
class CaptureAudioConfigured extends CaptureEvent {
  const CaptureAudioConfigured(this.config);

  final MirrorAudioConfig config;
}

class CaptureAudio extends CaptureEvent {
  const CaptureAudio(this.packet);

  final MirrorAudioPacket packet;
}

/// Capturing the sound stopped working. The pictures go on.
class CaptureAudioEnded extends CaptureEvent {
  const CaptureAudioEnded();
}

class CaptureScreenOff extends CaptureEvent {
  const CaptureScreenOff({required this.off});

  final bool off;
}

class CaptureEnded extends CaptureEvent {
  const CaptureEnded(this.end);

  final CaptureEnd end;
}
