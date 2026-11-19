import 'dart:ffi';
import 'dart:io';

import 'package:ferret_remote_input/src/linux/linux.dart';

/// Locks this computer's screen right away, as its own Lock Screen command
/// does: `SACLockScreenImmediate` on macOS (what the Apple menu's Lock
/// Screen calls), `LockWorkStation` on Windows, and logind on Linux.
abstract interface class ScreenLocker {
  /// The locker for the platform the app runs on.
  factory ScreenLocker.current() {
    if (Platform.isMacOS) {
      return MacScreenLocker();
    }

    if (Platform.isWindows) {
      return WindowsScreenLocker();
    }

    if (Platform.isLinux) {
      return LinuxScreenLocker();
    }

    return const UnsupportedScreenLocker();
  }

  /// Whether this platform can lock its screen at all.
  bool get isSupported;

  /// Locks the screen. False when it couldn't.
  Future<bool> lock();
}

/// Phones and anything else: nothing to lock from here.
class UnsupportedScreenLocker implements ScreenLocker {
  const UnsupportedScreenLocker();

  @override
  bool get isSupported => false;

  @override
  Future<bool> lock() async => false;
}

typedef _LockNative = Int32 Function();
typedef _Lock = int Function();

class MacScreenLocker implements ScreenLocker {
  static const _login =
      '/System/Library/PrivateFrameworks/login.framework/Versions/Current/login';

  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async {
    try {
      final library = DynamicLibrary.open(_login);
      final lockNow = library.lookupFunction<_LockNative, _Lock>(
        'SACLockScreenImmediate',
      );
      return lockNow() == 0;
    } on Object {
      return false;
    }
  }
}

class WindowsScreenLocker implements ScreenLocker {
  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async {
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final lockWorkStation = user32.lookupFunction<_LockNative, _Lock>(
        'LockWorkStation',
      );
      return lockWorkStation() != 0;
    } on Object {
      return false;
    }
  }
}

/// Asks logind to lock this session, which every desktop that locks on
/// suspend listens to. Falls back to the freedesktop screensaver call for
/// sessions logind doesn't know, such as some nested ones.
class LinuxScreenLocker implements ScreenLocker {
  LinuxScreenLocker({RunCommand? run}) : _run = run ?? Process.run;

  final RunCommand _run;

  static const _ways = [
    ('loginctl', ['lock-session']),
    ('xdg-screensaver', ['lock']),
    (
      'dbus-send',
      [
        '--session',
        '--dest=org.freedesktop.ScreenSaver',
        '--type=method_call',
        '/org/freedesktop/ScreenSaver',
        'org.freedesktop.ScreenSaver.Lock',
      ],
    ),
  ];

  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async {
    for (final (executable, arguments) in _ways) {
      try {
        final result = await _run(executable, arguments);
        if (result.exitCode == 0) {
          return true;
        }
      } on ProcessException {
        continue;
      }
    }

    return false;
  }
}
