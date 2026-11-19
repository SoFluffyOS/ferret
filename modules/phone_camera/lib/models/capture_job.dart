import 'package:phone_camera/models/picture_kind.dart';

/// Where a computer's request for a picture stands.
enum CaptureJobStatus {
  /// The phone shows the request; nobody answered yet.
  asking,

  /// The picture was taken and is on its way.
  receiving,

  done,

  /// The phone's owner answered Not now.
  declined,

  /// The camera closed without a picture.
  cancelled,

  /// The phone can't take that kind of picture.
  unsupported,

  /// The phone's system didn't let Ferret use the camera.
  noPermission,

  /// The phone's camera was already open for another request.
  busy,
  offline,
  failed,

  /// Nobody answered on the phone in time.
  expired;

  bool get isOpen => this == asking || this == receiving;
}

/// On a computer: one request for a picture from a phone, as one line in
/// Activity.
class CaptureJob {
  const CaptureJob({
    required this.id,
    required this.deviceId,
    required this.kind,
    required this.startedAt,
    this.status = .asking,
    this.fraction = 0,
    this.paths = const [],
    this.mimeType,
    this.onClipboard = false,
  });

  /// The request's id, as sent to the phone.
  final String id;

  /// The phone asked.
  final String deviceId;
  final PictureKind kind;
  final DateTime startedAt;
  final CaptureJobStatus status;
  final double fraction;

  /// Where the picture was saved here, once done.
  final List<String> paths;

  /// Such as `image/jpeg`, once the phone said.
  final String? mimeType;

  /// The picture was put on this computer's clipboard.
  final bool onClipboard;

  CaptureJob copyWith({
    CaptureJobStatus? status,
    double? fraction,
    List<String>? paths,
    String? mimeType,
    bool? onClipboard,
  }) => CaptureJob(
    id: id,
    deviceId: deviceId,
    kind: kind,
    startedAt: startedAt,
    status: status ?? this.status,
    fraction: fraction ?? this.fraction,
    paths: paths ?? this.paths,
    mimeType: mimeType ?? this.mimeType,
    onClipboard: onClipboard ?? this.onClipboard,
  );
}
