import 'package:ferret_clipboard/ferret_clipboard.dart';

/// Something this device's clipboard just took that may be kept, such as
/// on the shelf: copied here, or arrived from another device. Never a
/// private clip.
class ClipCopy {
  const ClipCopy({required this.content, required this.at, this.fromDeviceId});

  final ClipboardContent content;
  final DateTime at;

  /// The device it came from, or null when it was copied here.
  final String? fromDeviceId;
}
