import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// The few libc calls uinput needs, behind an interface so tests can record
/// them instead of touching `/dev/uinput`.
abstract interface class UinputSyscalls {
  /// Whether this process may write to [path].
  bool canWrite(String path);

  /// Opens [path] for writing without blocking; returns the fd, or -1.
  int openWrite(String path);

  /// `ioctl(fd, request, value)`; returns -1 on failure.
  int ioctlValue(int fd, int request, int value);

  /// `ioctl(fd, request, &bytes)`; returns -1 on failure.
  int ioctlBytes(int fd, int request, Uint8List bytes);

  /// Writes all of [bytes]; returns how many were written, or -1.
  int write(int fd, Uint8List bytes);

  void close(int fd);

  /// The size of a C `long`, which sets the size of `struct input_event`.
  int get longSize;
}

typedef _AccessC = Int Function(Pointer<Utf8>, Int);
typedef _AccessDart = int Function(Pointer<Utf8>, int);
typedef _OpenC = Int Function(Pointer<Utf8>, Int, VarArgs<(Int,)>);
typedef _OpenDart = int Function(Pointer<Utf8>, int, int);
typedef _IoctlValueC = Int Function(Int, UnsignedLong, VarArgs<(Long,)>);
typedef _IoctlValueDart = int Function(int, int, int);
typedef _IoctlPointerC = Int Function(
  Int,
  UnsignedLong,
  VarArgs<(Pointer<Uint8>,)>,
);
typedef _IoctlPointerDart = int Function(int, int, Pointer<Uint8>);
typedef _WriteC = IntPtr Function(Int, Pointer<Uint8>, Size);
typedef _WriteDart = int Function(int, Pointer<Uint8>, int);
typedef _CloseC = Int Function(Int);
typedef _CloseDart = int Function(int);

/// [UinputSyscalls] through libc with `dart:ffi`. Linux only.
class FfiUinputSyscalls implements UinputSyscalls {
  static const _writeOk = 2;
  static const _writeOnly = 0x1;
  static const _nonBlocking = 0x800;
  static const _closeOnExec = 0x80000;

  late final DynamicLibrary _libc = DynamicLibrary.process();
  late final _AccessDart _access = _libc.lookupFunction<_AccessC, _AccessDart>(
    'access',
  );
  late final _OpenDart _open = _libc.lookupFunction<_OpenC, _OpenDart>('open');
  late final _IoctlValueDart _ioctlValue = _libc
      .lookupFunction<_IoctlValueC, _IoctlValueDart>('ioctl');
  late final _IoctlPointerDart _ioctlPointer = _libc
      .lookupFunction<_IoctlPointerC, _IoctlPointerDart>('ioctl');
  late final _WriteDart _write = _libc.lookupFunction<_WriteC, _WriteDart>(
    'write',
  );
  late final _CloseDart _close = _libc.lookupFunction<_CloseC, _CloseDart>(
    'close',
  );

  @override
  int get longSize => sizeOf<Long>();

  @override
  bool canWrite(String path) =>
      using(
        (arena) => _access(path.toNativeUtf8(allocator: arena), _writeOk),
      ) ==
      0;

  @override
  int openWrite(String path) => using(
    (arena) => _open(
      path.toNativeUtf8(allocator: arena),
      _writeOnly | _nonBlocking | _closeOnExec,
      0,
    ),
  );

  @override
  int ioctlValue(int fd, int request, int value) =>
      _ioctlValue(fd, request, value);

  @override
  int ioctlBytes(int fd, int request, Uint8List bytes) => using((arena) {
    final pointer = arena<Uint8>(bytes.length);
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    return _ioctlPointer(fd, request, pointer);
  });

  @override
  int write(int fd, Uint8List bytes) => using((arena) {
    final pointer = arena<Uint8>(bytes.length);
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    return _write(fd, pointer, bytes.length);
  });

  @override
  void close(int fd) => _close(fd);
}
