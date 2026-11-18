import 'package:protocol/clipboard.dart';

/// Which way a clip went.
enum ClipDirection { sent, received }

/// Why a clip was not synced, or [none].
enum ClipSkip {
  none,

  /// The source app marked it as private and private items are off.
  sensitive,

  /// It is an image and images are off.
  imagesOff,

  /// It is bigger than the size limit.
  tooLarge,

  /// No connected device takes clipboard items.
  noDevices,

  /// Writing it to this device's clipboard failed.
  writeFailed,
}

/// One clip in the in-memory history.
class ClipEntry {
  const ClipEntry({
    required this.item,
    required this.direction,
    required this.at,
    this.deviceNames = const [],
    this.deviceIds = const [],
    this.skip = .none,
    this.onClipboard = false,
    this.redacted = false,
  });

  /// The clip. Its content is cleared once [redacted].
  final ClipItem item;
  final ClipDirection direction;

  /// When it was copied or arrived, in this device's clock.
  final DateTime at;

  /// The source device for a received clip; the devices it reached for a
  /// sent one.
  final List<String> deviceNames;

  /// The same devices as [deviceNames], by id.
  final List<String> deviceIds;
  final ClipSkip skip;

  /// It was put on this device's clipboard.
  final bool onClipboard;

  /// A private clip whose content was dropped after it expired.
  final bool redacted;

  String get id => item.id;

  bool get isSensitive => item.sensitive;

  bool get isImage => item.kind == ClipKind.CLIP_KIND_IMAGE;

  bool get hasContent => !redacted && skip != .sensitive;

  ClipEntry copyWith({bool? onClipboard, ClipSkip? skip}) => ClipEntry(
    item: item,
    direction: direction,
    at: at,
    deviceNames: deviceNames,
    deviceIds: deviceIds,
    skip: skip ?? this.skip,
    onClipboard: onClipboard ?? this.onClipboard,
    redacted: redacted,
  );

  /// The same entry with its content dropped, for private clips that expired.
  ClipEntry redact() => ClipEntry(
    item: ClipItem(
      id: item.id,
      kind: item.kind,
      createdAtMs: item.createdAtMs,
      sourceDeviceId: item.sourceDeviceId,
      sensitive: item.sensitive,
    ),
    direction: direction,
    at: at,
    deviceNames: deviceNames,
    deviceIds: deviceIds,
    skip: skip,
    onClipboard: onClipboard,
    redacted: true,
  );
}
