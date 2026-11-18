import 'dart:async';
import 'dart:io';

import 'package:drop/feature/drop_feature.dart';
import 'package:drop/models/models.dart';
import 'package:drop/platform/platform.dart';
import 'package:drop/services/services.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:interop_localsend/interop_localsend.dart';

/// What Drop's card and settings show, and what they can do.
class DropViewModel extends ChangeNotifier {
  DropViewModel({
    required this.feature,
    FerretDrop? plugin,
    Future<List<String>> Function()? pickFiles,
    Future<String?> Function()? pickFolder,
    Future<String> Function()? describeFolder,
    DateTime Function()? clock,
  }) : _plugin = plugin ?? FerretDrop(),
       _clock = clock ?? DateTime.now,
       _pickFiles = pickFiles ?? _openFiles,
       _pickFolder = pickFolder ?? getDirectoryPath,
       _describeFolder = describeFolder {
    _transfers = feature.transfers;
    _runningIds = _idsOfRunning(_transfers);
    _targets = _readTargets();
    _subscriptions
      ..add(feature.changes.listen(_onTransfers))
      ..add(feature.host.sessionChanges.listen((_) => _onSessions()))
      ..add(
        feature.host.settings.changes
            .where((key) => key.startsWith('${DropFeature.featureId}.'))
            .listen((_) => _onSettings()),
      )
      ..add(feature.localSend.changes.listen((_) => _onLocalSend()))
      ..add(feature.quickShare.changes.listen((_) => _onQuickShare()));
    _quickShareState = feature.quickShare.receiveState;
    _onLocalSend();
    unawaited(_loadFolder());
  }

  final DropFeature feature;
  final FerretDrop _plugin;
  final Future<List<String>> Function() _pickFiles;
  final Future<String?> Function() _pickFolder;
  final Future<String> Function()? _describeFolder;
  final DateTime Function() _clock;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<Transfer> _transfers = const [];
  Set<String> _runningIds = const {};
  int _finishedCount = 0;
  List<DropTarget> _targets = const [];
  List<DropTarget> _localSendTargets = const [];
  LocalSendReceiveState _receiveState = const LocalSendReceiveState();
  QuickShareReceiveState _quickShareState = const QuickShareReceiveState();
  Timer? _countdown;
  String _receiveFolder = '';

  /// Newest first.
  List<Transfer> get transfers => _transfers;

  bool get hasFinished =>
      _transfers.any((transfer) => !transfer.status.isActive);

  /// What Drop is in the middle of: transfers under way, offers waiting
  /// for an answer, and how many transfers went through so far.
  FeatureBusy get busy {
    final running = [
      for (final transfer in _transfers)
        if (transfer.status.isActive && !transfer.needsAnswer) transfer,
    ];
    final waiting = [
      for (final transfer in _transfers)
        if (transfer.status.isActive && transfer.needsAnswer) transfer,
    ];

    return FeatureBusy(
      progress: _progressOf(running),
      peerName: _sharedName(running),
      isSending: running.firstOrNull?.isOutgoing ?? true,
      waitingCount: waiting.length,
      waitingName: _sharedName(waiting),
      finishedCount: _finishedCount,
    );
  }

  /// Connected paired devices that can receive drops.
  List<DropTarget> get targets => _targets;

  /// LocalSend devices found on the network, when LocalSend is on.
  List<DropTarget> get localSendTargets => _localSendTargets;

  /// Whether Drop works with LocalSend devices at all.
  bool get localSendEnabled => feature.localSend.isEnabled;

  /// Whether the Send button has anywhere to send to, or to look.
  bool get canSend => _targets.isNotEmpty || localSendEnabled;

  bool get isScanning => feature.localSend.isScanning;

  LocalSendReceiveState get receiveState => _receiveState;

  bool get receiveAlways => feature.localSend.receiveAlways;

  /// Whole seconds left in the receive window, or null when it is off or
  /// stays on. Changes every second while the window is open.
  int? get receiveSecondsLeft => switch (_receiveState.remaining(_clock())) {
    final left? => (left.inMilliseconds / 1000).ceil(),
    null => null,
  };

  /// Whether Drop offers to be found by Quick Share on phones.
  bool get quickShareEnabled => feature.quickShare.isEnabled;

  /// Whether this platform can be found by Quick Share at all.
  bool get quickShareSupported => feature.quickShare.isSupported;

  QuickShareReceiveState get quickShareState => _quickShareState;

  /// Whole seconds this device stays visible to Quick Share, or null
  /// when it isn't. Changes every second while it is.
  int? get quickShareSecondsLeft =>
      switch (_quickShareState.remaining(_clock())) {
        final left? => (left.inMilliseconds / 1000).ceil(),
        null => null,
      };

  bool get autoAccept => feature.autoAccept;

  /// The receive folder's full path, or "Download/Ferret" on Android.
  String get receiveFolder => _receiveFolder;

  /// The receive folder as people read it, such as "Downloads › Ferret".
  String get receiveFolderLabel => FolderLabel.of(
    _receiveFolder,
    home: Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'],
  );

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

  /// Asks for files to send. Empty when nothing was picked.
  Future<List<String>> pickFiles() => _pickFiles();

  /// Whether the LocalSend device [target] left the network.
  bool isGone(DropTarget target) =>
      feature.localSend.peerFor(target.deviceId) == null;

  Future<Transfer?> sendFiles(
    String deviceId,
    List<String> paths, {
    bool temporary = false,
  }) => feature.sendFiles(deviceId, paths, temporary: temporary);

  /// Sends [text], or returns null when [deviceId] is a LocalSend device
  /// that left the network.
  Transfer? sendText(String deviceId, String text) {
    if (LocalSendIds.isLocalSend(deviceId)) {
      return feature.localSend.sendText(deviceId, text);
    }

    return feature.sendText(deviceId, text);
  }

  /// Looks for LocalSend devices on the network.
  Future<void> scan() => feature.localSend.scan();

  /// Lets LocalSend devices send here for the next 10 minutes.
  Future<void> receiveFromLocalSend() => feature.localSend.receiveForAWhile();

  /// Stops receiving from LocalSend, also when it was set to stay on.
  Future<void> stopReceiving() async {
    if (receiveAlways) {
      await feature.localSend.setReceiveAlways(false);
      return;
    }

    await feature.localSend.stopReceiving();
  }

  Future<void> setReceiveAlways(bool value) =>
      feature.localSend.setReceiveAlways(value);

  Future<void> setLocalSendEnabled(bool value) =>
      feature.localSend.setEnabled(value);

  /// Makes this device show up in Quick Share on phones for the next 10
  /// minutes.
  Future<void> receiveFromQuickShare() => feature.quickShare.receiveForAWhile();

  /// Hides this device from Quick Share now.
  Future<void> stopQuickShare() => feature.quickShare.stopReceiving();

  Future<void> setQuickShareEnabled(bool value) =>
      feature.quickShare.setEnabled(value);

  bool needsPin(Transfer transfer) => feature.needsPin(transfer);

  Future<void> retryWithPin(Transfer transfer, String pin) =>
      feature.retryWithPin(transfer.id, pin.trim());

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
    _countdown?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  void _onTransfers(List<Transfer> transfers) {
    for (final transfer in transfers) {
      final wasRunning = _runningIds.contains(transfer.id);
      if (wasRunning && transfer.status == .done) {
        _finishedCount++;
      }
    }

    _runningIds = _idsOfRunning(transfers);
    _transfers = transfers;
    notifyListeners();
  }

  Set<String> _idsOfRunning(List<Transfer> transfers) => {
    for (final transfer in transfers)
      if (transfer.status.isActive) transfer.id,
  };

  /// Bytes done over bytes to move, across [running]; null when none run.
  double? _progressOf(List<Transfer> running) {
    if (running.isEmpty) {
      return null;
    }

    final total = running.fold(0, (sum, transfer) => sum + transfer.totalBytes);
    if (total <= 0) {
      return 0;
    }

    final done = running.fold(0, (sum, transfer) => sum + transfer.bytesDone);
    return (done / total).clamp(0, 1).toDouble();
  }

  /// The one device [transfers] are with, or empty when they are with
  /// several.
  String _sharedName(List<Transfer> transfers) {
    final names = {for (final transfer in transfers) transfer.deviceName};
    if (names.length != 1) {
      return '';
    }

    return names.first;
  }

  void _onSessions() {
    _targets = _readTargets();
    notifyListeners();
  }

  void _onLocalSend() {
    _receiveState = feature.localSend.receiveState;
    _localSendTargets = _readLocalSendTargets();
    _restartCountdown();
    notifyListeners();
  }

  void _onQuickShare() {
    _quickShareState = feature.quickShare.receiveState;
    _restartCountdown();
    notifyListeners();
  }

  /// Ticks every second while a receive window is counting down.
  void _restartCountdown() {
    _countdown?.cancel();
    _countdown = null;
    final now = _clock();
    final counting =
        _receiveState.remaining(now) != null ||
        _quickShareState.remaining(now) != null;
    if (!counting) {
      return;
    }

    _countdown = .periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  List<DropTarget> _readLocalSendTargets() {
    if (!localSendEnabled) {
      return const [];
    }

    return [
      for (final peer in feature.localSend.peers)
        DropTarget(
          deviceId: LocalSendIds.deviceId(peer.fingerprint),
          name: peer.info.alias,
          formFactor: switch (peer.info.deviceType) {
            LocalSendDeviceType.mobile => .FORM_FACTOR_PHONE,
            LocalSendDeviceType.server => .FORM_FACTOR_SERVER,
            LocalSendDeviceType.desktop => .FORM_FACTOR_DESKTOP,
            LocalSendDeviceType.web ||
            LocalSendDeviceType.headless => .FORM_FACTOR_UNSPECIFIED,
          },
          platform: switch (peer.info.deviceType) {
            LocalSendDeviceType.web => .PLATFORM_BROWSER,
            LocalSendDeviceType.headless => .PLATFORM_CLI,
            _ => .PLATFORM_UNSPECIFIED,
          },
          isLocalSend: true,
          detail: peer.info.deviceModel ?? '',
        ),
    ];
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
