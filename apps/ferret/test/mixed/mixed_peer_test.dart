// One side of a mixed-version run: scripts/mixed_versions.sh starts this
// file in this checkout and in an older one, each with its own data folder,
// and drives both from scripts/mixed_versions.dart over a local socket.
// The same source has to build against the older checkout too, so it only
// uses what both have. Without FERRET_MIXED_CONTROL it is skipped.
import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;
import 'dart:io' as io show Platform;

import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lan_discovery/lan_discovery.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

final _control = io.Platform.environment['FERRET_MIXED_CONTROL'];

void main() {
  test(
    'mixed-version peer',
    () async => _Peer().run(int.parse(_control!)),
    skip: _control == null ? 'Run by scripts/mixed_versions.sh' : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

class _Peer {
  final _env = io.Platform.environment;
  late final String _home = _env['FERRET_MIXED_HOME']!;
  late final Socket _socket;
  final _clipboard = _MemoryClipboard();
  final _discovery = _PipeDiscovery();
  late FerretEngine _engine;
  late DropFeature _drop;
  final _done = Completer<void>();

  void _say(Map<String, Object?> event) => _socket.writeln(jsonEncode(event));

  Future<void> run(int port) async {
    _socket = await Socket.connect('127.0.0.1', port);
    _discovery.onAnnounce = (announce) => _say({
      'event': 'announce',
      'data': base64Encode(announce.writeToBuffer()),
    });
    _clipboard.onWrite = (text) => _say({'event': 'clip', 'text': text});
    await _open();
    _say({
      'event': 'ready',
      'role': _env['FERRET_MIXED_ROLE'],
      'id': _engine.identity.deviceId,
    });

    _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => unawaited(_handle(line)));
    await _done.future;
    await _engine.stop();
    await _socket.close();
  }

  Future<void> _open() async {
    _drop = DropFeature(
      store: (_) => FolderReceiveStore(() async => p.join(_home, 'inbox')),
    );
    _engine = await FerretEngine.create(
      secrets: FileSecretStore(p.join(_home, 'secrets')),
      settings: await JsonFileSettingsStore.open(p.join(_home, 'settings')),
      device: LocalDevice(
        name: _env['FERRET_MIXED_NAME'] ?? 'Peer',
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [
        ClipboardFeature(clipboard: () => _clipboard),
        _drop,
      ],
      discovery: _discovery,
      port: 0,
    );
    await _engine.start();
  }

  Future<void> _handle(String line) async {
    final command = jsonDecode(line) as Map<String, dynamic>;
    final id = command['id'];
    try {
      final reply = await _run(command);
      _say({'event': 'reply', 'id': id, ...reply});
    } on Object catch (error) {
      _say({'event': 'reply', 'id': id, 'error': '$error'});
    }
  }

  Future<Map<String, Object?>> _run(Map<String, dynamic> command) async {
    switch (command['cmd']) {
      case 'heard':
        _discovery.hear(
          Announce.fromBuffer(base64Decode(command['data'] as String)),
        );
        return {};
      case 'offer':
        final handle = await _engine.createPairingOffer();
        return {'qr': handle.qrText};
      case 'pair':
        final offer = PairingCodes.parseOffer(command['qr'] as String)!;
        offer
          ..hosts.clear()
          ..hosts.add('127.0.0.1');
        final outcome = await _engine.pairWithOffer(offer);
        return {'outcome': outcome.runtimeType.toString()};
      case 'status':
        return {
          'sessions': [
            for (final session in _engine.sessions) session.remoteDeviceId,
          ],
          'trusted': [
            for (final device in _engine.trustStore.devices) device.id,
          ],
          'features': {
            for (final session in _engine.sessions)
              session.remoteDeviceId: [
                for (final feature in session.remoteHello?.features ?? [])
                  feature.id,
              ],
          },
          'protocol': {
            for (final session in _engine.sessions)
              session.remoteDeviceId: session.remoteDevice?.protocolVersion,
          },
        };
      case 'copy':
        _clipboard.copy(command['text'] as String);
        return {};
      case 'send':
        final transfer = await _drop.sendFiles(command['to'] as String, [
          command['path'] as String,
        ]);
        if (transfer == null) {
          return {'status': 'not sent'};
        }

        final deadline = DateTime.now().add(const Duration(seconds: 60));
        while (DateTime.now().isBefore(deadline)) {
          final status = _drop.registry[transfer.id]?.status;
          if (status != null && !status.isActive) {
            return {'status': status.name};
          }

          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        return {'status': 'timed out'};
      case 'restart':
        await _engine.stop();
        await _engine.start();
        return {};
      case 'codec':
        return _codec(command);
      case 'quit':
        _done.complete();
        return {};
    }

    throw ArgumentError('Unknown command ${command['cmd']}');
  }

  /// How this build writes and reads what discovery puts on the network.
  Map<String, Object?> _codec(Map<String, dynamic> command) {
    final self = Announce(
      protocolVersion: 1,
      deviceId: _engine.identity.deviceId,
      name: 'Café ☕ laptop',
      platform: .PLATFORM_MACOS,
      formFactor: .FORM_FACTOR_LAPTOP,
      port: 47640,
    );
    final read = <String, Object?>{};
    if (command['multicast'] case final String packet) {
      read['multicast'] = decodeAnnounce(base64Decode(packet))?.deviceId;
    }

    if (command['question'] case final String packet) {
      read['question'] = decodeAnnounce(base64Decode(packet))?.deviceId;
    }

    if (command['txt'] case final Map<String, dynamic> txt) {
      read['txt'] = MdnsDiscovery.announceFrom(
        MdnsInstance(
          name: txt['id'] as String,
          address: InternetAddress.loopbackIPv4,
          port: 47640,
          txt: txt.cast<String, String>(),
        ),
      )?.name;
    }

    return {
      'multicast': base64Encode(encodeAnnounce(self)),
      'txt': MdnsDiscovery.serviceFor(self).txt,
      'read': read,
    };
  }
}

/// Discovery through the controller: what this side announces goes out as
/// an event, and the other side's announces come back as `heard`.
class _PipeDiscovery implements Discovery {
  final StreamController<DiscoveredPeer> _peers = StreamController.broadcast();
  void Function(Announce announce)? onAnnounce;
  Announce? _self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  void hear(Announce announce) =>
      _peers.add(DiscoveredPeer(announce: announce, host: '127.0.0.1'));

  @override
  Future<void> start(Announce self) async {
    _self = self;
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    if (_self case final self?) {
      onAnnounce?.call(self);
    }
  }

  @override
  Future<void> stop() async => _self = null;
}

class _MemoryClipboard implements ClipboardPlatform {
  final StreamController<void> _changes = StreamController.broadcast();
  void Function(String text)? onWrite;
  ClipboardContent? _content;

  void copy(String text) {
    _content = ClipboardContent.text(text);
    _changes.add(null);
  }

  @override
  ClipboardAccess get access => ClipboardAccess.always;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<ClipboardContent?> read() async => _content;

  @override
  Future<void> write(ClipboardContent written) async {
    _content = written;
    onWrite?.call(written.text ?? '');
    _changes.add(null);
  }

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}
}
