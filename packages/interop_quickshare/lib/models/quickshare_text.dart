import 'package:interop_quickshare/models/quickshare_text_kind.dart';

/// A text, link, address or phone number a sender announced. The content
/// itself only arrives after the offer is accepted.
class QuickShareText {
  const QuickShareText({
    required this.payloadId,
    required this.kind,
    required this.size,
    this.title = '',
  });

  /// The id the text's payload carries on the connection.
  final int payloadId;
  final QuickShareTextKind kind;

  /// The length of the content in bytes.
  final int size;

  /// A shortened preview the sender made, such as the start of a link.
  final String title;
}
