import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/services.dart';
import 'package:engine/engine.dart';
import 'package:path/path.dart' as p;
import 'package:protobuf/protobuf.dart';
import 'package:protocol/drop.dart';
import 'package:protocol/protocol.dart' hide Platform;

/// Builds the [ReceiveStore] once settings are available.
typedef ReceiveStoreFactory = ReceiveStore Function(SettingsStore settings);

/// The engine side of Drop: files and text between paired devices.
///
/// The Ferret protocol lives in [DropSender] and [DropReceiver]; both report
/// to one [TransferRegistry] and save through one [ReceiveStore], so another
/// transport can plug into the same list and folder later.
class DropFeature extends Feature {
  DropFeature({
    ReceiveStoreFactory? store,
    this.chunkSize = DropSender.defaultChunkSize,
    this.ackEvery = DropSender.defaultAckEvery,
  }) : _storeFactory = store ?? _defaultStore;

  static const featureId = 'drop';

  final int chunkSize;
  final int ackEvery;
  final ReceiveStoreFactory _storeFactory;
  final TransferRegistry registry = TransferRegistry();

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
      store: _storeFactory(host.settings),
      sessionFor: host.sessionFor,
      deviceName: _deviceName,
      autoAccept: () => autoAccept,
    );
  }

  @override
  Future<void> stop() => _receiver.dispose();

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

    return _sender.sendFiles(deviceId, files, temporary: temporary);
  }

  Transfer sendText(String deviceId, String text) =>
      _sender.sendText(deviceId, text);

  Future<void> cancel(String id) async {
    if (_sender.owns(id)) {
      await _sender.cancel(id);
      return;
    }

    await _receiver.cancel(id);
  }

  /// Whether Retry can pick [transfer] up again from this device.
  bool canRetry(Transfer transfer) {
    if (!transfer.canRetry) {
      return false;
    }

    return switch (transfer.isOutgoing) {
      true => _sender.owns(transfer.id),
      false => _receiver.ownsJob(transfer.id),
    };
  }

  Future<void> retry(String id) async {
    if (_sender.owns(id)) {
      await _sender.retry(id);
      return;
    }

    await _receiver.retry(id);
  }

  /// Accepts or declines an offer waiting for this device's answer.
  void answer(String id, {required bool accept}) =>
      _receiver.answer(id, accept: accept);

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
