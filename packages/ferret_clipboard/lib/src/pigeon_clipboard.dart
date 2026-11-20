import 'dart:async';
import 'dart:io';

import 'package:ferret_clipboard/src/clipboard_access.dart';
import 'package:ferret_clipboard/src/clipboard_content.dart';
import 'package:ferret_clipboard/src/clipboard_platform.dart';
import 'package:ferret_clipboard/src/messages.g.dart';

/// The clipboard through the native plugin (Android, iOS, macOS, Windows).
class PigeonClipboard implements ClipboardPlatform, ClipboardFlutterApi {
  PigeonClipboard({ClipboardHostApi? api, ClipboardAccess? access})
    : _api = api ?? ClipboardHostApi(),
      access = access ?? _accessOfThisPlatform() {
    ClipboardFlutterApi.setUp(this);
  }

  final ClipboardHostApi _api;
  final StreamController<void> _changes = .broadcast();

  @override
  final ClipboardAccess access;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<ClipboardContent?> read() async {
    final clip = await _api.read();
    if (clip == null) {
      return null;
    }

    if (clip.text case final text? when text.isNotEmpty) {
      return ClipboardContent.text(
        text,
        sensitive: clip.sensitive,
        files: clip.filePaths ?? const [],
      );
    }

    if ((clip.image, clip.imageMime) case (final image?, final mime?)
        when image.isNotEmpty) {
      return ClipboardContent.image(
        image,
        imageMime: mime,
        sensitive: clip.sensitive,
      );
    }

    return null;
  }

  @override
  Future<void> write(ClipboardContent content) => _api.write(
    PlatformClip(
      text: content.text,
      image: content.image,
      imageMime: content.imageMime,
      sensitive: content.sensitive,
    ),
  );

  @override
  Future<void> startWatching() => _api.startWatching();

  @override
  Future<void> stopWatching() => _api.stopWatching();

  @override
  void onChanged() => _changes.add(null);

  static ClipboardAccess _accessOfThisPlatform() {
    if (Platform.isAndroid) {
      return .foreground;
    }

    if (Platform.isIOS) {
      return .onRequest;
    }

    return .always;
  }
}
