import 'package:ferret_drop/src/content_files.dart';
import 'package:flutter/services.dart';

/// Android's document picker for files to send. It returns `content://`
/// URIs that [ContentFiles] reads while sending, so nothing is copied
/// first; release each one once it is sent.
abstract final class FilePicks {
  static const _channel = MethodChannel('io.sofluffy.ferret_drop/pick');

  /// The URIs picked, or empty when nothing was picked or the picker
  /// couldn't open.
  static Future<List<String>> open() async {
    try {
      final paths = await _channel.invokeListMethod<String>('pickFiles');
      return paths ?? const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }
}
