import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/clipboard.dart';

/// Turns clipboard content into [ClipItem]s and back, and fingerprints it.
class ClipCodec {
  ClipCodec({Random? random}) : _random = random ?? Random.secure();

  static final _link = RegExp(r'^https?://\S+$', caseSensitive: false);

  final Random _random;

  /// A fingerprint of what [content] holds, the same on every device.
  static String hashOf(ClipboardContent content) {
    final bytes = switch (content.image) {
      final Uint8List image => [0x69, ...image],
      null => [0x74, ...utf8.encode(content.text ?? '')],
    };
    return sha256.convert(bytes).toString();
  }

  static int sizeOf(ClipboardContent content) => switch (content.image) {
    final Uint8List image => image.length,
    null => utf8.encode(content.text ?? '').length,
  };

  /// Wraps [content], copied on [sourceDeviceId] at [at], in a new item.
  ClipItem itemFor(
    ClipboardContent content, {
    required String sourceDeviceId,
    required DateTime at,
  }) {
    final hash = hashOf(content);
    final item = ClipItem(
      id: _newId(),
      kind: kindOf(content),
      createdAtMs: Int64(at.millisecondsSinceEpoch),
      sourceDeviceId: sourceDeviceId,
      sensitive: content.sensitive,
      contentHash: _hexToBytes(hash),
    );

    if (content.image case final image?) {
      return item
        ..image = image
        ..imageMime = content.imageMime ?? 'image/png';
    }

    return item..text = content.text ?? '';
  }

  /// What [item] puts on the clipboard, or null when it holds nothing usable.
  static ClipboardContent? contentOf(ClipItem item) {
    if (item.kind == ClipKind.CLIP_KIND_IMAGE) {
      if (item.image.isEmpty) {
        return null;
      }

      final mime = switch (item.imageMime) {
        '' => 'image/png',
        final mime => mime,
      };
      return ClipboardContent.image(
        Uint8List.fromList(item.image),
        imageMime: mime,
        sensitive: item.sensitive,
      );
    }

    if (item.text.isEmpty) {
      return null;
    }

    return ClipboardContent.text(item.text, sensitive: item.sensitive);
  }

  static ClipKind kindOf(ClipboardContent content) {
    if (content.isImage) {
      return .CLIP_KIND_IMAGE;
    }

    if (_link.hasMatch((content.text ?? '').trim())) {
      return .CLIP_KIND_URL;
    }

    return .CLIP_KIND_TEXT;
  }

  String _newId() {
    final bytes = List.generate(12, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static List<int> _hexToBytes(String hex) => [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
}
