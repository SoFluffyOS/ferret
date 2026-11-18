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

class CaptureScreenOff extends CaptureEvent {
  const CaptureScreenOff({required this.off});

  final bool off;
}

class CaptureEnded extends CaptureEvent {
  const CaptureEnded(this.end);

  final CaptureEnd end;
}
