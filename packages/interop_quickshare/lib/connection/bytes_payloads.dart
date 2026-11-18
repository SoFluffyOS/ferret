import 'dart:typed_data';

import 'package:interop_quickshare/models/models.dart';
import 'package:interop_quickshare/proto/proto.dart';

/// Puts small payloads back together from their chunks. Control frames
/// and shared texts travel this way; files are written to disk instead.
class BytesPayloads {
  BytesPayloads({this.maxBytes = 1024 * 1024, this.maxOpen = 8});

  /// A payload that grows past this ends the connection.
  final int maxBytes;

  /// How many payloads may be half-received at once.
  final int maxOpen;

  final Map<int, BytesBuilder> _open = {};

  /// Adds one chunk. Returns the payload's id and bytes once its last
  /// chunk arrived, or null while more are expected.
  (int, Uint8List)? add(PayloadTransfer transfer) {
    final id = transfer.payloadHeader.id.toInt();
    final chunk = transfer.payloadChunk;
    final builder = _open[id] ?? BytesBuilder(copy: false);
    if (!_open.containsKey(id) && _open.length >= maxOpen) {
      throw const QuickShareException(.protocol, 'Too many payloads');
    }

    if (builder.length + chunk.body.length > maxBytes) {
      throw const QuickShareException(.protocol, 'Payload too long');
    }

    builder.add(chunk.body);
    if (chunk.flags & PayloadFlags.lastChunk == 0) {
      _open[id] = builder;
      return null;
    }

    _open.remove(id);
    return (id, builder.takeBytes());
  }
}

/// The bits of a payload chunk's flags.
abstract final class PayloadFlags {
  static const lastChunk = 0x1;
}
