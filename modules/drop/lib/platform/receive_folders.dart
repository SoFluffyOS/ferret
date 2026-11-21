import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where received files go on each platform, honouring the setting.
abstract final class ReceiveFolders {
  /// Android keeps a folder name inside Downloads; desktops keep a path.
  static bool get usesFolderName => defaultTargetPlatform == .android;

  /// Whether people can pick another folder here.
  static bool get canChange => defaultTargetPlatform != .iOS;

  /// The folder name inside Downloads, for Android.
  static String folderName(SettingsStore settings) {
    final wanted = settings.get<String>(DropSettings.receiveFolder)?.trim();
    if (wanted == null ||
        wanted.isEmpty ||
        wanted.contains('/') ||
        wanted.startsWith('.')) {
      return DropSettings.defaultFolderName;
    }

    return wanted;
  }

  /// The receive folder path for desktops, iOS, and Android before 10.
  static Future<String> path(SettingsStore settings) async {
    if (Platform.isAndroid) {
      return p.join(await _androidAppDownloads(), folderName(settings));
    }

    if (Platform.isIOS) {
      final documents = await getApplicationDocumentsDirectory();
      return p.join(documents.path, DropSettings.defaultFolderName);
    }

    final chosen = settings.get<String>(DropSettings.receiveFolder);
    if (chosen != null && p.isAbsolute(chosen)) {
      return chosen;
    }

    return p.join(await _downloads(), DropSettings.defaultFolderName);
  }

  static Future<String> _downloads() async {
    try {
      if (await getDownloadsDirectory() case final downloads?) {
        return downloads.path;
      }
    } on UnsupportedError {
      // Falls through to the home folder below.
    }

    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        (await getApplicationDocumentsDirectory()).path;
    return p.join(home, 'Downloads');
  }

  static Future<String> _androidAppDownloads() async {
    final folders = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    if (folders case [final first, ...]) {
      return first.path;
    }

    return (await getApplicationDocumentsDirectory()).path;
  }
}
