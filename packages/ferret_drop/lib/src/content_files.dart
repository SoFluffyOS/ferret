import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

/// What Android says about a shared `content://` URI.
class ContentInfo {
  const ContentInfo({
    required this.name,
    required this.size,
    required this.mime,
    this.modified,
  });

  final String name;

  /// Bytes, or -1 when the app that shared it doesn't say.
  final int size;
  final String mime;
  final DateTime? modified;
}

/// Reads one opened `content://` URI from the start, a block at a time.
abstract interface class ContentReader {
  /// Bytes the app that shared it reported on open, or null when unknown.
  int? get length;

  /// Up to [max] next bytes; empty at the end.
  Future<Uint8List> read(int max);

  Future<void> close();
}

/// Reads files other apps shared as `content://` URIs straight from their
/// app, so a share never has to be copied first.
abstract interface class ContentSource {
  /// Name, size and type of [uri], or null when it can't be read any more.
  Future<ContentInfo?> describe(String uri);

  /// Opens [uri] at its first byte. Throws [FileSystemException] when it
  /// can't be read.
  Future<ContentReader> open(String uri);

  /// Copies [uri] into Ferret's cache and returns the copy's path, for an
  /// app that doesn't say how big it is. Null when the copy failed.
  Future<String?> copy(String uri);

  /// Lets go of the permission to read [uri], once it is sent.
  Future<void> release(String uri);
}

/// [ContentSource] on Android, through the drop plugin.
class ContentFiles implements ContentSource {
  const ContentFiles();

  static const _channel = MethodChannel('io.sofluffy.ferret_drop/content');

  static bool isContent(String location) => location.startsWith('content://');

  @override
  Future<ContentInfo?> describe(String uri) async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>(
        'describe',
        uri,
      );
      if (info == null) {
        return null;
      }

      final modified = info['modified'] as int?;
      return ContentInfo(
        name: info['name'] as String? ?? 'shared',
        size: info['size'] as int? ?? -1,
        mime: info['mime'] as String? ?? '',
        modified: switch (modified) {
          final ms? when ms > 0 => DateTime.fromMillisecondsSinceEpoch(ms),
          _ => null,
        },
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<ContentReader> open(String uri) async {
    try {
      final opened = await _channel.invokeMapMethod<String, Object?>(
        'open',
        uri,
      );
      final handle = opened?['handle'] as int?;
      if (handle == null) {
        throw FileSystemException('Could not open shared content', uri);
      }

      final length = opened?['length'] as int? ?? -1;
      return _ChannelReader(handle, length >= 0 ? length : null);
    } on PlatformException catch (error) {
      throw FileSystemException(error.message ?? 'Could not open', uri);
    } on MissingPluginException {
      throw FileSystemException('No content reader on this platform', uri);
    }
  }

  @override
  Future<String?> copy(String uri) async {
    try {
      return await _channel.invokeMethod<String>('copy', uri);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> release(String uri) async {
    try {
      await _channel.invokeMethod<void>('release', uri);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

/// Fetches 1 MB blocks over the channel, one ahead of the reads, so the
/// next block is on its way while this one is sent.
class _ChannelReader implements ContentReader {
  _ChannelReader(this._handle, this.length);

  static const _block = 1024 * 1024;

  final int _handle;

  @override
  final int? length;

  Future<Uint8List>? _next;
  Uint8List _buffer = Uint8List(0);
  int _at = 0;
  bool _ended = false;

  @override
  Future<Uint8List> read(int max) async {
    if (_at >= _buffer.length) {
      if (_ended) {
        return Uint8List(0);
      }

      final block = await (_next ?? _fetch());
      _next = null;
      if (block.isEmpty) {
        _ended = true;
        return block;
      }

      _buffer = block;
      _at = 0;
      _next = _fetch()..ignore();
    }

    final end = min(_at + max, _buffer.length);
    final bytes = Uint8List.sublistView(_buffer, _at, end);
    _at = end;
    return bytes;
  }

  Future<Uint8List> _fetch() async {
    try {
      final bytes = await ContentFiles._channel.invokeMethod<Uint8List>(
        'read',
        {'handle': _handle, 'length': _block},
      );
      return bytes ?? Uint8List(0);
    } on PlatformException catch (error) {
      throw FileSystemException(error.message ?? 'Could not read', '');
    }
  }

  @override
  Future<void> close() async {
    try {
      await _next;
    } on FileSystemException {
      // The read in flight failed; closing still lets go of the stream.
    }

    try {
      await ContentFiles._channel.invokeMethod<void>('close', _handle);
    } on PlatformException {
      return;
    }
  }
}
