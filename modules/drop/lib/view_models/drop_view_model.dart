import 'dart:async';
import 'dart:io';

import 'package:drop/feature/drop_feature.dart';
import 'package:drop/models/models.dart';
import 'package:drop/platform/platform.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What Drop's card and settings show, and what they can do.
class DropViewModel extends ChangeNotifier {
  DropViewModel({
    required this.feature,
    FerretDrop? plugin,
    Future<List<String>> Function()? pickFiles,
    Future<String?> Function()? pickFolder,
    Future<String> Function()? describeFolder,
  }) : _plugin = plugin ?? FerretDrop(),
       _pickFiles = pickFiles ?? _openFiles,
       _pickFolder = pickFolder ?? getDirectoryPath,
       _describeFolder = describeFolder {
    _transfers = feature.transfers;
    _targets = _readTargets();
    _subscriptions
      ..add(feature.changes.listen(_onTransfers))
      ..add(feature.host.sessionChanges.listen((_) => _onSessions()))
      ..add(
        feature.host.settings.changes
            .where((key) => key.startsWith('${DropFeature.featureId}.'))
            .listen((_) => _onSettings()),
      );
    unawaited(_loadFolder());
  }

  final DropFeature feature;
  final FerretDrop _plugin;
  final Future<List<String>> Function() _pickFiles;
  final Future<String?> Function() _pickFolder;
  final Future<String> Function()? _describeFolder;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<Transfer> _transfers = const [];
  List<DropTarget> _targets = const [];
  String _receiveFolder = '';

  /// Newest first.
  List<Transfer> get transfers => _transfers;

  bool get hasFinished =>
      _transfers.any((transfer) => !transfer.status.isActive);

  /// Connected devices that can receive drops.
  List<DropTarget> get targets => _targets;

  bool get autoAccept => feature.autoAccept;

  /// The receive folder as people should read it.
  String get receiveFolder => _receiveFolder;

  bool get canChangeFolder => ReceiveFolders.canChange;

  bool get usesFolderName => ReceiveFolders.usesFolderName;

  String get folderName => ReceiveFolders.folderName(feature.host.settings);

  /// Whether someone picked a folder other than the default.
  bool get hasCustomFolder => switch (feature.host.settings.get<String>(
    DropSettings.receiveFolder,
  )) {
    final folder? => folder.trim().isNotEmpty,
    null => false,
  };

  bool canRetry(Transfer transfer) => feature.canRetry(transfer);

  Future<void> setAutoAccept(bool value) async {
    await feature.setAutoAccept(value);
    notifyListeners();
  }

  /// Asks for files, then sends them to [deviceId]. Returns null when
  /// nothing was picked or nothing could be sent.
  Future<Transfer?> pickAndSend(String deviceId) async {
    final paths = await _pickFiles();
    if (paths.isEmpty) {
      return null;
    }

    return feature.sendFiles(deviceId, paths);
  }

  Future<Transfer?> sendFiles(
    String deviceId,
    List<String> paths, {
    bool temporary = false,
  }) => feature.sendFiles(deviceId, paths, temporary: temporary);

  Transfer sendText(String deviceId, String text) =>
      feature.sendText(deviceId, text);

  Future<void> cancel(Transfer transfer) => feature.cancel(transfer.id);

  Future<void> retry(Transfer transfer) => feature.retry(transfer.id);

  void accept(Transfer transfer) => feature.answer(transfer.id, accept: true);

  void decline(Transfer transfer) => feature.answer(transfer.id, accept: false);

  void dismiss(Transfer transfer) => feature.dismiss(transfer.id);

  void clearFinished() => feature.clearFinished();

  /// Opens a single received file, or shows several in their folder.
  Future<void> open(Transfer transfer) async {
    if (transfer.files case [final file]) {
      if (file.location case final location?) {
        await _plugin.open(location, mimeType: file.mime);
      }

      return;
    }

    await reveal(transfer);
  }

  Future<void> reveal(Transfer transfer) async {
    for (final file in transfer.files) {
      if (file.location case final location?) {
        await _plugin.reveal(location);
        return;
      }
    }
  }

  Future<void> copy(Transfer transfer) => copyText(transfer.text ?? '');

  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Asks for a new receive folder on desktop.
  Future<void> pickReceiveFolder() async {
    final folder = await _pickFolder();
    if (folder == null) {
      return;
    }

    await feature.host.settings.set(DropSettings.receiveFolder, folder);
  }

  /// Sets the folder name inside Downloads, on Android.
  Future<void> setFolderName(String name) =>
      feature.host.settings.set(DropSettings.receiveFolder, name.trim());

  Future<void> resetReceiveFolder() =>
      feature.host.settings.set(DropSettings.receiveFolder, null);

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  void _onTransfers(List<Transfer> transfers) {
    _transfers = transfers;
    notifyListeners();
  }

  void _onSessions() {
    _targets = _readTargets();
    notifyListeners();
  }

  void _onSettings() {
    notifyListeners();
    unawaited(_loadFolder());
  }

  Future<void> _loadFolder() async {
    final describe = _describeFolder ?? _describe;
    final folder = await describe();
    if (folder == _receiveFolder) {
      return;
    }

    _receiveFolder = folder;
    notifyListeners();
  }

  Future<String> _describe() async {
    final settings = feature.host.settings;
    if (Platform.isAndroid && await _plugin.canSaveToDownloads()) {
      return 'Download/${ReceiveFolders.folderName(settings)}';
    }

    return ReceiveFolders.path(settings);
  }

  List<DropTarget> _readTargets() => [
    for (final session in feature.targets)
      DropTarget(
        deviceId: session.remoteDeviceId,
        name: session.remoteDevice?.name ?? '',
        formFactor:
            session.remoteDevice?.formFactor ?? .FORM_FACTOR_UNSPECIFIED,
        platform: session.remoteDevice?.platform ?? .PLATFORM_UNSPECIFIED,
      ),
  ];

  static Future<List<String>> _openFiles() async {
    final files = await openFiles();
    return [for (final file in files) file.path];
  }
}
