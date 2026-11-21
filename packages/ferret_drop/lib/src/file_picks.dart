import 'package:flutter/services.dart';

/// Android's document picker for files to send. The picked files are
/// copied into Ferret's cache with streams, so a big pick never has to fit
/// in memory; delete the copies once they are sent.
abstract final class FilePicks {
  static const _channel = MethodChannel('io.sofluffy.ferret_drop/pick');

  /// Paths of the copies of the files picked, or empty when nothing was
  /// picked or the picker couldn't open.
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
