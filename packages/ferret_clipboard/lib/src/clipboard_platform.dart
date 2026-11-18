import 'dart:io';

import 'package:ferret_clipboard/src/clipboard_access.dart';
import 'package:ferret_clipboard/src/clipboard_content.dart';
import 'package:ferret_clipboard/src/linux_clipboard.dart';
import 'package:ferret_clipboard/src/pigeon_clipboard.dart';

/// The system clipboard on one platform.
abstract interface class ClipboardPlatform {
  /// The clipboard of the platform the app runs on.
  factory ClipboardPlatform.current() {
    if (Platform.isLinux) {
      return LinuxClipboard();
    }

    return PigeonClipboard();
  }

  ClipboardAccess get access;

  /// Fires when the clipboard may have changed, after [startWatching].
  Stream<void> get changes;

  /// What the clipboard holds, or null when it is empty, holds something
  /// other than text or an image, or can't be read right now.
  Future<ClipboardContent?> read();

  /// Replaces the clipboard with [content].
  Future<void> write(ClipboardContent content);

  Future<void> startWatching();

  Future<void> stopWatching();
}
