import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/services.dart';
import 'package:engine/engine.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:interop_quickshare/interop_quickshare.dart'
    show QuickShareDeviceKind;
import 'package:path/path.dart' as p;
import 'package:protobuf/protobuf.dart';
import 'package:protocol/drop.dart';
import 'package:protocol/protocol.dart' hide Platform;

/// Builds the [ReceiveStore] once settings are available.
typedef ReceiveStoreFactory = ReceiveStore Function(SettingsStore settings);

/// The engine side of Drop: files and text between paired devices.
///
/// The Ferret protocol lives in [DropSender] and [DropReceiver]; LocalSend
/// devices are reached through [localSend], and Android phones send in
/// through [quickShare]. All of them report to one [TransferRegistry] and
/// save through one [ReceiveStore].
class DropFeature extends Feature {
  DropFeature({
    ReceiveStoreFactory? store,
    this.chunkSize = DropSender.defaultChunkSize,
    this.ackEvery = DropSender.defaultAckEvery,
    this.localSendOptions = const LocalSendOptions(),
    this.quickShareOptions = const QuickShareOptions(),
    SecretStore? secrets,
  }) : _storeFactory = store ?? _defaultStore,
       _secrets = secrets;

  static const featureId = 'drop';

  final int chunkSize;
  final int ackEvery;
  final LocalSendOptions localSendOptions;
  final QuickShareOptions quickShareOptions;
  final ReceiveStoreFactory _storeFactory;

  /// Keeps this device's LocalSend certificate. Without it, the device
  /// gets a new LocalSend fingerprint each time the app starts.
  final SecretStore? _secrets;
  final TransferRegistry registry = TransferRegistry();

  /// Sending to and receiving from LocalSend devices.
  late final LocalSendBridge localSend;

  /// Receiving from Android phones through Quick Share.
  late final QuickShareBridge quickShare;

  late final DropSender _sender;
  late final DropReceiver _receiver;

  @override
  String get id => featureId;

  @override
  List<String> get flags => const ['send', 'receive', 'resume'];

  /// Newest first.
  List<Transfer> get transfers => registry.all;

  /// The whole list after each change.
  Stream<List<Transfer>> get changes => registry.changes;

  /// Each transfer as it changes.
  Stream<Transfer> get updates => registry.updates;

  bool get autoAccept =>
      host.settings.get<bool>(DropSettings.autoAccept) ?? true;

  Future<void> setAutoAccept(bool value) =>
      host.settings.set(DropSettings.autoAccept, value);

  /// Connected devices that can receive drops.
  List<Session> get targets => [
    for (final session in host.sessions)
      if (session.supports(featureId)) session,
  ];

  @override
  Future<void> onStart() async {
    final store = _storeFactory(host.settings);
    localSend = LocalSendBridge(
      registry: registry,
      store: store,
      settings: host.settings,
      describeSelf: _describeSelf,
      secrets: _secrets,
      options: localSendOptions,
    );
    unawaited(localSend.start());
    quickShare = QuickShareBridge(
      registry: registry,
      store: store,
      settings: host.settings,
      describeSelf: _describeSelfForQuickShare,
      options: quickShareOptions,
    );
    _sender = DropSender(
      featureId: featureId,
      registry: registry,
      sessionFor: host.sessionFor,
      deviceName: _deviceName,
      chunkSize: chunkSize,
      ackEvery: ackEvery,
    );
    _receiver = DropReceiver(
      featureId: featureId,
      registry: registry,
      store: store,
      sessionFor: host.sessionFor,
      deviceName: _deviceName,
      autoAccept: () => autoAccept,
    );
  }

  @override
  Future<void> stop() async {
    await localSend.dispose();
    await quickShare.dispose();
    await _receiver.dispose();
  }

  /// Sends the files at [paths] to [deviceId]. Folders and missing files
  /// are skipped; returns null when nothing is left to send. [temporary]
  /// files are deleted once the transfer ends.
  Future<Transfer?> sendFiles(
    String deviceId,
    List<String> paths, {
    bool temporary = false,
  }) async {
    final files = [
      for (final path in paths) ?await OutgoingFile.fromPath(path),
    ];
    if (files.isEmpty) {
      return null;
    }

    if (LocalSendIds.isLocalSend(deviceId)) {
      return localSend.sendFiles(deviceId, files, temporary: temporary);
    }

    return _sender.sendFiles(deviceId, files, temporary: temporary);
  }

  /// Sends [text] to the paired device [deviceId]. Text for a LocalSend
  /// device goes through [localSend].
  Transfer sendText(String deviceId, String text) =>
      _sender.sendText(deviceId, text);

  Future<void> cancel(String id) async {
    if (localSend.owns(id)) {
      await localSend.cancel(id);
      return;
    }

    if (quickShare.owns(id)) {
      await quickShare.cancel(id);
      return;
    }

    if (_sender.owns(id)) {
      await _sender.cancel(id);
      return;
    }

    await _receiver.cancel(id);
  }

  /// Whether Retry can pick [transfer] up again from this device.
  bool canRetry(Transfer transfer) {
    if (!transfer.canRetry || transfer.failure == .pinRequired) {
      return false;
    }

    if (transfer.isLocalSend) {
      return localSend.sender.owns(transfer.id);
    }

    return switch (transfer.isOutgoing) {
      true => _sender.owns(transfer.id),
      false => _receiver.ownsJob(transfer.id),
    };
  }

  Future<void> retry(String id) async {
    if (localSend.sender.owns(id)) {
      await localSend.sender.retry(id);
      return;
    }

    if (_sender.owns(id)) {
      await _sender.retry(id);
      return;
    }

    await _receiver.retry(id);
  }

  /// Whether [transfer] stopped because the LocalSend receiver wants a
  /// PIN, and can be sent again with one.
  bool needsPin(Transfer transfer) =>
      transfer.status == .failed &&
      transfer.failure == .pinRequired &&
      localSend.sender.owns(transfer.id);

  /// Offers a LocalSend transfer again with the receiver's [pin].
  Future<void> retryWithPin(String id, String pin) =>
      localSend.sender.retry(id, pin: pin);

  /// Accepts or declines an offer waiting for this device's answer.
  void answer(String id, {required bool accept}) {
    if (localSend.receiver.owns(id)) {
      localSend.receiver.answer(id, accept: accept);
      return;
    }

    if (quickShare.owns(id)) {
      quickShare.receiver.answer(id, accept: accept);
      return;
    }

    _receiver.answer(id, accept: accept);
  }

  /// Removes a finished transfer from the list.
  void dismiss(String id) {
    if (registry[id]?.status.isActive ?? true) {
      return;
    }

    registry.remove(id);
  }

  void clearFinished() => registry.clearFinished();

  @override
  void onSessionOpened(Session session) => _receiver.onSessionOpened(session);

  @override
  void onSessionClosed(Session session) => _receiver.onSessionClosed(session);

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, Chunk.new) case final chunk?) {
      final received = await _receiver.onChunk(session, chunk);
      if (received == null && envelope.expectsReply) {
        await session
            .replyError(envelope, .ERROR_CODE_CANCELLED)
            .catchError((Object _) {});
      }

      return received;
    }

    if (payloadOf(envelope, TransferOffer.new) case final offer?) {
      return _receiver.onOffer(session, offer);
    }

    if (payloadOf(envelope, FileComplete.new) case final complete?) {
      return _receiver.onFileComplete(session, complete);
    }

    if (payloadOf(envelope, TransferComplete.new) case final complete?) {
      await _receiver.onTransferComplete(session, complete);
      return null;
    }

    if (payloadOf(envelope, ResumeRequest.new) case final request?) {
      await _sender.onResumeRequest(session, request);
      return null;
    }

    if (payloadOf(envelope, Cancel.new) case final cancel?) {
      await _sender.onCancel(session, cancel);
      await _receiver.onCancel(session, cancel);
      return null;
    }

    printDebug('Drop ignored ${envelope.type}');
    return null;
  }

  String _deviceName(String deviceId) {
    if (host.sessionFor(deviceId)?.remoteDevice case final device?) {
      return device.name;
    }

    for (final device in host.trustStore.devices) {
      if (device.id == deviceId) {
        return device.name;
      }
    }

    return '';
  }

  ({String alias, String model, LocalSendDeviceType type}) _describeSelf() {
    final device = host.localDevice;
    return (
      alias: device.name,
      model: switch (device.platform) {
        .PLATFORM_ANDROID => 'Android',
        .PLATFORM_IOS => 'iOS',
        .PLATFORM_MACOS => 'macOS',
        .PLATFORM_LINUX => 'Linux',
        .PLATFORM_WINDOWS => 'Windows',
        _ => 'Ferret',
      },
      type: switch (device.formFactor) {
        .FORM_FACTOR_PHONE || .FORM_FACTOR_TABLET => .mobile,
        .FORM_FACTOR_SERVER => .server,
        .FORM_FACTOR_LAPTOP || .FORM_FACTOR_DESKTOP => .desktop,
        _ => switch (device.platform) {
          .PLATFORM_ANDROID || .PLATFORM_IOS => .mobile,
          .PLATFORM_CLI => .headless,
          _ => .desktop,
        },
      },
    );
  }

  ({String name, QuickShareDeviceKind kind}) _describeSelfForQuickShare() {
    final device = host.localDevice;
    return (
      name: device.name,
      kind: switch (device.formFactor) {
        .FORM_FACTOR_PHONE => .phone,
        .FORM_FACTOR_TABLET => .tablet,
        .FORM_FACTOR_LAPTOP || .FORM_FACTOR_DESKTOP => .laptop,
        _ => switch (device.platform) {
          .PLATFORM_ANDROID || .PLATFORM_IOS => .phone,
          .PLATFORM_MACOS || .PLATFORM_LINUX || .PLATFORM_WINDOWS => .laptop,
          _ => .unknown,
        },
      },
    );
  }

  static ReceiveStore _defaultStore(SettingsStore settings) =>
      FolderReceiveStore(() async {
        if (settings.get<String>(DropSettings.receiveFolder) case final folder?
            when p.isAbsolute(folder)) {
          return folder;
        }

        final home =
            Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            Directory.systemTemp.path;
        return p.join(home, 'Downloads', DropSettings.defaultFolderName);
      });
}
