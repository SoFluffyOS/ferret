import 'dart:ffi';

/// Whether this Windows account has the screen, unlocked. The input
/// desktop can't be opened from a session that was switched away from, and
/// can't be switched to while the lock screen holds it.
class WindowsSessionProbe {
  WindowsSessionProbe() : _user32 = DynamicLibrary.open('user32.dll');

  static const _desktopSwitchDesktop = 0x0100;

  final DynamicLibrary _user32;

  late final _openInputDesktop = _user32
      .lookupFunction<
        IntPtr Function(Uint32, Int32, Uint32),
        int Function(int, int, int)
      >('OpenInputDesktop');

  late final _switchDesktop = _user32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'SwitchDesktop',
      );

  late final _closeDesktop = _user32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'CloseDesktop',
      );

  bool isActive() {
    final desktop = _openInputDesktop(0, 0, _desktopSwitchDesktop);
    if (desktop == 0) {
      return false;
    }

    final switched = _switchDesktop(desktop) != 0;
    _closeDesktop(desktop);
    return switched;
  }
}
