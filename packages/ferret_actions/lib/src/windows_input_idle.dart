import 'dart:ffi';

import 'package:ferret_actions/src/input_idle.dart';
import 'package:ffi/ffi.dart';

final class _LastInputInfo extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwTime;
}

typedef _GetLastInputInfoNative = Int32 Function(Pointer<_LastInputInfo>);
typedef _GetLastInputInfo = int Function(Pointer<_LastInputInfo>);
typedef _GetTickCountNative = Uint32 Function();
typedef _GetTickCount = int Function();

/// `GetLastInputInfo` against `GetTickCount`, both in milliseconds since
/// boot. They wrap after 49 days, so the gap is taken modulo 2³².
class WindowsInputIdle implements InputIdle {
  const WindowsInputIdle();

  static const _tickRange = 0x100000000;

  @override
  Future<Duration?> idleTime() async {
    final info = calloc<_LastInputInfo>();
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final getLastInputInfo = user32
          .lookupFunction<_GetLastInputInfoNative, _GetLastInputInfo>(
            'GetLastInputInfo',
          );
      final getTickCount = kernel32
          .lookupFunction<_GetTickCountNative, _GetTickCount>('GetTickCount');

      info.ref.cbSize = sizeOf<_LastInputInfo>();
      if (getLastInputInfo(info) == 0) {
        return null;
      }

      final milliseconds = (getTickCount() - info.ref.dwTime) % _tickRange;
      return Duration(milliseconds: milliseconds);
    } on Object {
      return null;
    } finally {
      calloc.free(info);
    }
  }
}
