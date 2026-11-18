import 'package:drop/services/outgoing_file.dart';
import 'package:drop/services/progress_throttle.dart';
import 'package:drop/services/speed_meter.dart';
import 'package:interop_localsend/interop_localsend.dart';

/// What the LocalSend sender remembers about one transfer, so Retry can
/// offer it again.
class LocalSendOutgoingJob {
  LocalSendOutgoingJob({
    required this.id,
    required this.peer,
    required this.files,
    this.text,
    this.temporary = false,
  });

  final String id;
  final LocalSendPeer peer;
  final List<OutgoingFile> files;
  final String? text;

  /// The files are copies made for this transfer and are deleted once it
  /// finishes.
  final bool temporary;

  final SpeedMeter speed = SpeedMeter();
  final ProgressThrottle throttle = ProgressThrottle();

  /// The run in progress, if any.
  LocalSendSendJob? running;
  bool cancelled = false;
}
