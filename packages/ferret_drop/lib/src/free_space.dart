import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

/// How much room is left where received files land.
///
/// Android, iPhone and Mac ask the platform, which knows the space the
/// system would free for a file the user wants (a Mac's purgeable space
/// counts). Linux and Windows read the volume directly.
abstract final class FreeSpace {
  static const _channel = MethodChannel('io.sofluffy.ferret_drop/space');

  /// Bytes an app may still write on the volume that holds [path], or null
  /// when that can't be told here. [path] may not exist yet; the nearest
  /// folder above it that does is asked.
  static Future<int?> of(String path) async {
    try {
      final existing = await _existing(path);
      if (Platform.isLinux) {
        return _Statvfs.free(existing);
      }

      if (Platform.isWindows) {
        return _WindowsDisk.free(existing);
      }

      return await _channel.invokeMethod<int>('freeBytes', existing);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on Object {
      return null;
    }
  }

  /// Opens the system's storage settings, where it has them (Android).
  /// Returns false when nothing opened.
  static Future<bool> openStorageSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openStorageSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<String> _existing(String path) async {
    var current = Directory(path);
    while (!await current.exists()) {
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }

      current = parent;
    }

    return current.path;
  }
}

typedef _StatvfsNative = Int32 Function(Pointer<Utf8>, Pointer<Uint8>);
typedef _StatvfsDart = int Function(Pointer<Utf8>, Pointer<Uint8>);

/// glibc's `statvfs` on 64-bit Linux: `f_frsize` sits at byte 8 and
/// `f_bavail`, the blocks an unprivileged app may use, at byte 32.
abstract final class _Statvfs {
  static const _bufferSize = 256;
  static const _frsizeOffset = 8;
  static const _bavailOffset = 32;

  static int? free(String path) {
    if (sizeOf<IntPtr>() != 8) {
      return null;
    }

    final statvfs = DynamicLibrary.process()
        .lookupFunction<_StatvfsNative, _StatvfsDart>('statvfs');
    final buffer = calloc<Uint8>(_bufferSize);
    final nativePath = path.toNativeUtf8();
    try {
      if (statvfs(nativePath, buffer) != 0) {
        return null;
      }

      final fields = buffer.cast<Uint64>();
      final blockSize = fields[_frsizeOffset ~/ 8];
      final available = fields[_bavailOffset ~/ 8];
      return blockSize * available;
    } finally {
      calloc
        ..free(buffer)
        ..free(nativePath);
    }
  }
}

typedef _GetDiskFreeSpaceExNative = Int32 Function(
  Pointer<Utf16>,
  Pointer<Uint64>,
  Pointer<Uint64>,
  Pointer<Uint64>,
);
typedef _GetDiskFreeSpaceExDart = int Function(
  Pointer<Utf16>,
  Pointer<Uint64>,
  Pointer<Uint64>,
  Pointer<Uint64>,
);

/// `GetDiskFreeSpaceExW`: the bytes free to this user, which honours disk
/// quotas.
abstract final class _WindowsDisk {
  static int? free(String path) {
    final getDiskFreeSpaceEx = DynamicLibrary.open('kernel32.dll')
        .lookupFunction<_GetDiskFreeSpaceExNative, _GetDiskFreeSpaceExDart>(
          'GetDiskFreeSpaceExW',
        );
    final available = calloc<Uint64>();
    final nativePath = path.toNativeUtf16();
    try {
      if (getDiskFreeSpaceEx(nativePath, available, nullptr, nullptr) == 0) {
        return null;
      }

      return available.value;
    } finally {
      calloc
        ..free(available)
        ..free(nativePath);
    }
  }
}
