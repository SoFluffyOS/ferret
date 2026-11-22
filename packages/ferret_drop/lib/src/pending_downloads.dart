import 'dart:ffi';
import 'dart:io';

import 'package:ferret_drop/src/messages.g.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

/// A file still arriving in Downloads, written in place.
abstract interface class PendingWriter {
  /// Appends [bytes].
  Future<void> write(List<int> bytes);

  Future<void> close();
}

/// Files received straight into the shared Downloads folder on Android 10
/// and newer. Each one stays a pending MediaStore item, which no other app
/// sees, until [publish]; so a half file never shows in Downloads.
abstract interface class PendingDownloads {
  /// Makes a pending file called [name] (or `name (1)` when taken) in
  /// `Download/<folder>`, open for writing from its first byte.
  Future<({String uri, PendingWriter writer})> create({
    required String folder,
    required String name,
    required String mime,
  });

  /// Opens pending [uri] again, cut back to its first [offset] bytes and
  /// writing after them. Null when it is gone.
  Future<PendingWriter?> open(String uri, int offset);

  /// Bytes in pending [uri], or null when it is gone.
  Future<int?> size(String uri);

  /// SHA-256 of what pending [uri] holds, read back.
  Future<Uint8List> sha256(String uri);

  /// Shows [uri] in Downloads under the name it got.
  Future<SavedFile> publish(String uri);

  /// Throws pending [uri] away.
  Future<void> delete(String uri);
}

/// [PendingDownloads] through the drop plugin. Bytes go straight to the
/// file descriptor Android hands out, with no copy through the channel.
class MediaStoreDownloads implements PendingDownloads {
  const MediaStoreDownloads();

  static const _channel = MethodChannel('io.sofluffy.ferret_drop/downloads');

  @override
  Future<({String uri, PendingWriter writer})> create({
    required String folder,
    required String name,
    required String mime,
  }) async {
    final created = await _call(
      () => _channel.invokeMapMethod<String, Object?>('create', {
        'folder': folder,
        'name': name,
        'mime': mime,
      }),
    );
    final uri = created?['uri'] as String?;
    final fd = created?['fd'] as int?;
    if (uri == null || fd == null) {
      throw FileSystemException('Downloads refused the file', name);
    }

    return (uri: uri, writer: DescriptorWriter(fd));
  }

  @override
  Future<PendingWriter?> open(String uri, int offset) async {
    final int? fd;
    try {
      fd = await _channel.invokeMethod<int>('open', uri);
    } on PlatformException catch (error) {
      if (error.code == 'gone') {
        return null;
      }

      throw FileSystemException(error.message ?? 'Could not open', uri);
    }

    if (fd == null) {
      return null;
    }

    final writer = DescriptorWriter(fd);
    try {
      writer.cutTo(offset);
    } on FileSystemException {
      await writer.close();
      rethrow;
    }

    return writer;
  }

  @override
  Future<int?> size(String uri) async {
    final size = await _call(() => _channel.invokeMethod<int>('size', uri));
    return switch (size) {
      final bytes? when bytes >= 0 => bytes,
      _ => null,
    };
  }

  @override
  Future<Uint8List> sha256(String uri) async {
    final digest = await _call(
      () => _channel.invokeMethod<Uint8List>('sha256', uri),
    );
    if (digest == null) {
      throw FileSystemException('Could not read the file back', uri);
    }

    return digest;
  }

  @override
  Future<SavedFile> publish(String uri) async {
    final saved = await _call(
      () => _channel.invokeMapMethod<String, Object?>('publish', uri),
    );
    return SavedFile(
      location: saved?['location'] as String? ?? uri,
      name: saved?['name'] as String? ?? '',
    );
  }

  @override
  Future<void> delete(String uri) =>
      _call(() => _channel.invokeMethod<void>('delete', uri));

  static Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw FileSystemException(error.message ?? error.code);
    } on MissingPluginException {
      throw const FileSystemException('No Downloads writer on this platform');
    }
  }
}

/// Writes to an open file descriptor, which it owns and closes. Each write
/// is one `pwrite` at the position it reached, so nothing seeks. Bytes go
/// through one native buffer that grows to the biggest write.
class DescriptorWriter implements PendingWriter {
  DescriptorWriter(this._fd, {int position = 0}) : _position = position;

  final int _fd;
  int _position;
  bool _closed = false;
  Pointer<Uint8> _buffer = nullptr;
  int _capacity = 0;

  /// Cuts the file back to [length] bytes and writes after them.
  void cutTo(int length) {
    if (_Libc.instance.ftruncate(_fd, length) != 0) {
      throw _errnoFailure('Could not cut the file back');
    }

    _position = length;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (_closed) {
      throw const FileSystemException('The file is closed');
    }

    if (bytes.isEmpty) {
      return;
    }

    if (bytes.length > _capacity) {
      malloc.free(_buffer);
      _buffer = malloc<Uint8>(bytes.length);
      _capacity = bytes.length;
    }

    _buffer.asTypedList(bytes.length).setAll(0, bytes);
    var done = 0;
    while (done < bytes.length) {
      final count = _Libc.instance.pwrite(
        _fd,
        _buffer + done,
        bytes.length - done,
        _position,
      );
      if (count < 0) {
        if (_Libc.instance.errno == _Libc.interrupted) {
          continue;
        }

        throw _errnoFailure('Could not write the file');
      }

      done += count;
      _position += count;
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    malloc.free(_buffer);
    _buffer = nullptr;
    _capacity = 0;
    _Libc.instance.close(_fd);
  }
}

FileSystemException _errnoFailure(String message) =>
    FileSystemException(message, '', OSError('', _Libc.instance.errno));

typedef _PwriteNative = IntPtr Function(Int32, Pointer<Uint8>, UintPtr, Int64);
typedef _PwriteDart = int Function(int, Pointer<Uint8>, int, int);
typedef _FtruncateNative = Int32 Function(Int32, Int64);
typedef _FtruncateDart = int Function(int, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);
typedef _ErrnoNative = Pointer<Int32> Function();
typedef _ErrnoDart = Pointer<Int32> Function();

/// The few libc calls that write a file descriptor. Android and Linux name
/// the 64-bit offset versions `pwrite64`/`ftruncate64`; Apple's are 64-bit
/// already.
final class _Libc {
  _Libc._(DynamicLibrary library, {required bool apple})
    : pwrite = library.lookupFunction<_PwriteNative, _PwriteDart>(
        apple ? 'pwrite' : 'pwrite64',
        isLeaf: true,
      ),
      ftruncate = library.lookupFunction<_FtruncateNative, _FtruncateDart>(
        apple ? 'ftruncate' : 'ftruncate64',
        isLeaf: true,
      ),
      close = library.lookupFunction<_CloseNative, _CloseDart>(
        'close',
        isLeaf: true,
      ),
      _errno = library.lookupFunction<_ErrnoNative, _ErrnoDart>(
        apple
            ? '__error'
            : Platform.isAndroid
            ? '__errno'
            : '__errno_location',
        isLeaf: true,
      );

  static final instance = switch (Platform.operatingSystem) {
    'android' => _Libc._(DynamicLibrary.open('libc.so'), apple: false),
    'macos' || 'ios' => _Libc._(DynamicLibrary.process(), apple: true),
    _ => _Libc._(DynamicLibrary.process(), apple: false),
  };

  static const interrupted = 4;

  final _PwriteDart pwrite;
  final _FtruncateDart ftruncate;
  final _CloseDart close;
  final _ErrnoDart _errno;

  int get errno => _errno().value;
}
