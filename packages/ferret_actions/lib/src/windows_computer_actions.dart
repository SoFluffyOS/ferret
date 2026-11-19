import 'dart:ffi';

import 'package:ferret_actions/src/computer_action.dart';
import 'package:ferret_actions/src/computer_actions.dart';
import 'package:ffi/ffi.dart';

/// `SetSuspendState` for sleep, `ExitWindowsEx` for restart and shut down
/// (with `SeShutdownPrivilege` turned on first, which every interactive
/// user holds but no process starts with), and the volume keys for sound.
class WindowsComputerActions implements ComputerActions {
  const WindowsComputerActions();

  static const _tokenAdjustPrivileges = 0x0020;
  static const _tokenQuery = 0x0008;
  static const _privilegeEnabled = 0x00000002;

  static const _exitReboot = 0x00000002;
  static const _exitPowerOff = 0x00000008;

  /// Closes apps that don't answer, but lets the others save first.
  static const _exitForceIfHung = 0x00000010;

  /// SHTDN_REASON_MAJOR_OTHER | SHTDN_REASON_FLAG_PLANNED.
  static const _reasonPlanned = 0x80000000;

  static const _keyUp = 0x0002;
  static const _keyVolumeMute = 0xAD;
  static const _keyVolumeDown = 0xAE;
  static const _keyVolumeUp = 0xAF;

  @override
  Set<ComputerAction> get supported => ComputerAction.values.toSet();

  @override
  Future<bool> run(ComputerAction action) async {
    try {
      return switch (action) {
        .sleep => _sleep(),
        .restart => _exitWindows(_exitReboot | _exitForceIfHung),
        .shutDown => _exitWindows(_exitPowerOff | _exitForceIfHung),
        .toggleMute => _pressKey(_keyVolumeMute),
        .volumeUp => _pressKey(_keyVolumeUp),
        .volumeDown => _pressKey(_keyVolumeDown),
      };
    } on Object {
      return false;
    }
  }

  bool _sleep() {
    final powrprof = DynamicLibrary.open('powrprof.dll');
    final setSuspendState = powrprof
        .lookupFunction<
          Uint8 Function(Uint8, Uint8, Uint8),
          int Function(int, int, int)
        >('SetSuspendState');

    return setSuspendState(0, 0, 0) != 0;
  }

  bool _exitWindows(int flags) {
    if (!_holdShutdownPrivilege()) {
      return false;
    }

    final user32 = DynamicLibrary.open('user32.dll');
    final exitWindowsEx = user32
        .lookupFunction<Int32 Function(Uint32, Uint32), int Function(int, int)>(
          'ExitWindowsEx',
        );

    return exitWindowsEx(flags, _reasonPlanned) != 0;
  }

  bool _holdShutdownPrivilege() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final advapi32 = DynamicLibrary.open('advapi32.dll');
    final getCurrentProcess = kernel32
        .lookupFunction<IntPtr Function(), int Function()>('GetCurrentProcess');
    final closeHandle = kernel32
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'CloseHandle',
        );
    final openProcessToken = advapi32
        .lookupFunction<
          Int32 Function(IntPtr, Uint32, Pointer<IntPtr>),
          int Function(int, int, Pointer<IntPtr>)
        >('OpenProcessToken');
    final lookupPrivilegeValue = advapi32
        .lookupFunction<
          Int32 Function(Pointer<Utf16>, Pointer<Utf16>, Pointer<Int64>),
          int Function(Pointer<Utf16>, Pointer<Utf16>, Pointer<Int64>)
        >('LookupPrivilegeValueW');
    final adjustTokenPrivileges = advapi32
        .lookupFunction<
          Int32 Function(
            IntPtr,
            Int32,
            Pointer<_TokenPrivileges>,
            Uint32,
            Pointer<Void>,
            Pointer<Void>,
          ),
          int Function(
            int,
            int,
            Pointer<_TokenPrivileges>,
            int,
            Pointer<Void>,
            Pointer<Void>,
          )
        >('AdjustTokenPrivileges');

    final token = calloc<IntPtr>();
    final luid = calloc<Int64>();
    final privileges = calloc<_TokenPrivileges>();
    final name = 'SeShutdownPrivilege'.toNativeUtf16();
    try {
      final opened = openProcessToken(
        getCurrentProcess(),
        _tokenAdjustPrivileges | _tokenQuery,
        token,
      );
      if (opened == 0) {
        return false;
      }

      if (lookupPrivilegeValue(nullptr, name, luid) == 0) {
        closeHandle(token.value);
        return false;
      }

      privileges.ref
        ..count = 1
        ..luid = luid.value
        ..attributes = _privilegeEnabled;
      final adjusted = adjustTokenPrivileges(
        token.value,
        0,
        privileges,
        0,
        nullptr,
        nullptr,
      );
      closeHandle(token.value);

      return adjusted != 0;
    } finally {
      calloc
        ..free(token)
        ..free(luid)
        ..free(privileges)
        ..free(name);
    }
  }

  bool _pressKey(int key) {
    final user32 = DynamicLibrary.open('user32.dll');
    final keyboardEvent = user32
        .lookupFunction<
          Void Function(Uint8, Uint8, Uint32, UintPtr),
          void Function(int, int, int, int)
        >('keybd_event');
    keyboardEvent(key, 0, 0, 0);
    keyboardEvent(key, 0, _keyUp, 0);

    return true;
  }
}

/// `TOKEN_PRIVILEGES` with its one `LUID_AND_ATTRIBUTES`. A LUID is two
/// 32-bit halves aligned to 4 bytes, so the struct is packed to keep the
/// 64-bit field at offset 4.
@Packed(4)
final class _TokenPrivileges extends Struct {
  @Uint32()
  external int count;

  @Int64()
  external int luid;

  @Uint32()
  external int attributes;
}
