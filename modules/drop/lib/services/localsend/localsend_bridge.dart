import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/localsend/localsend_identity_store.dart';
import 'package:drop/services/localsend/localsend_ids.dart';
import 'package:drop/services/localsend/localsend_receiver.dart';
import 'package:drop/services/localsend/localsend_sender.dart';
import 'package:drop/services/outgoing_file.dart';
import 'package:drop/services/receive_store.dart';
import 'package:drop/services/send_sources.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:transport/transport.dart' show MulticastHold, MulticastNeed;

/// Drop's LocalSend side: finds LocalSend devices, sends to them, and,
/// only while someone turned it on, receives from them.
///
/// Nothing touches the network until [scan], a send or a receive window
/// asks for it.
class LocalSendBridge {
  LocalSendBridge({
    required this.registry,
    required ReceiveStore store,
    required this.settings,
    required this.describeSelf,
    SecretStore? secrets,
    this.options = const LocalSendOptions(),
    DateTime Function()? clock,
    SendSources sources = const SendSources(),
    this.multicastNeed,
  }) : _identities = LocalSendIdentityStore(secrets),
       _clock = clock ?? DateTime.now,
       receiver = LocalSendReceiver(
         registry: registry,
         store: store,
         answerTimeout: options.answerTimeout,
       ) {
    sender = LocalSendSender(
      registry: registry,
      client: _readyClient,
      self: _selfInfo,
      sources: sources,
    );
    receiver.cancelSession = (sessionId) async =>
        _server?.cancelSession(sessionId);
    _discovery = LocalSendDiscovery(
      self: () => _self,
      shouldAnswer: () => _server?.isRunning ?? false,
      register: _registerWith,
      port: options.port,
    );
    _subscriptions.add(_discovery.changes.listen((_) => _emit()));
  }

  static const _discoveryIdle = Duration(minutes: 2);
  static const _busyRecheck = Duration(seconds: 5);

  final TransferRegistry registry;
  final SettingsStore settings;
  final LocalSendOptions options;

  /// Held while LocalSend's multicast group is joined, so Android's Wi-Fi
  /// passes what LocalSend devices send there.
  final MulticastNeed? multicastNeed;

  /// This device's name, model and kind, as LocalSend devices will see
  /// them.
  final ({String alias, String model, LocalSendDeviceType type}) Function()
  describeSelf;

  final LocalSendReceiver receiver;
  late final LocalSendSender sender;

  final LocalSendIdentityStore _identities;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final LocalSendDiscovery _discovery;

  LocalSendIdentity? _identity;
  LocalSendClient? _client;
  LocalSendServer? _server;
  DateTime? _until;
  Timer? _windowTimer;
  Timer? _discoveryTimer;
  LocalSendProblem? _problem;
  bool _starting = false;
  bool _suspended = false;
  DateTime? _suspendedUntil;
  int _scans = 0;
  bool _disposed = false;
  MulticastHold? _hearing;

  /// Fires when devices, scanning or the receive state change.
  Stream<void> get changes => _changes.stream;

  /// Whether Drop works with LocalSend devices at all.
  bool get isEnabled =>
      settings.get<bool>(DropSettings.localSendEnabled) ?? true;

  bool get receiveAlways =>
      settings.get<bool>(DropSettings.localSendReceiveAlways) ?? false;

  bool get isScanning => _scans > 0;

  /// LocalSend devices heard recently.
  List<LocalSendPeer> get peers => _discovery.peers;

  LocalSendReceiveState get receiveState => LocalSendReceiveState(
    isOn: _server?.isRunning ?? false,
    isStarting: _starting,
    until: _until,
    alias: describeSelf().alias,
    port: _server?.boundPort,
    problem: _problem,
  );

  /// Turns receiving back on after a restart when it was set to stay on.
  Future<void> start() async {
    if (!receiveAlways || !isEnabled) {
      return;
    }

    await _startReceiving(until: null);
  }

  /// Receives for [LocalSendOptions.receiveWindow], then turns itself
  /// off.
  Future<void> receiveForAWhile() =>
      _startReceiving(until: _clock().add(options.receiveWindow));

  /// Keeps receiving on, also after a restart, or turns it off.
  Future<void> setReceiveAlways(bool value) async {
    await settings.set(DropSettings.localSendReceiveAlways, value);
    if (value) {
      await _startReceiving(until: null);
      return;
    }

    await stopReceiving();
  }

  /// Turns LocalSend on or off in Drop. Off also stops receiving and
  /// forgets the devices found.
  Future<void> setEnabled(bool value) async {
    await settings.set(DropSettings.localSendEnabled, value);
    if (value) {
      _emit();
      return;
    }

    await settings.set(DropSettings.localSendReceiveAlways, false);
    _discovery.clear();
    await stopReceiving();
  }

  /// Stops receiving now. Offers waiting for an answer are declined and
  /// running LocalSend receives stop.
  Future<void> stopReceiving() async {
    _suspended = false;
    _suspendedUntil = null;
    _windowTimer?.cancel();
    _windowTimer = null;
    _until = null;
    _problem = null;
    await receiver.cancelAll();
    final server = _server;
    _server = null;
    await server?.stop();
    _releaseDiscoverySoon();
    _emit();
  }

  /// Whether receiving waits for Ferret to come back to the front.
  bool get isSuspended => _suspended;

  /// Ferret went to the background where the system stops it, such as on
  /// an iPhone: stops listening cleanly so LocalSend devices stop seeing
  /// this one, and remembers to listen again in [resume]. Offers waiting
  /// for an answer are declined; a transfer running now can't go on.
  Future<void> suspend() async {
    if (_suspended || !(_server?.isRunning ?? false)) {
      return;
    }

    _suspended = true;
    _suspendedUntil = _until;
    _windowTimer?.cancel();
    _windowTimer = null;
    _until = null;
    await receiver.cancelAll();
    final server = _server;
    _server = null;
    await server?.stop();
    await _discovery.stop();
    _followDiscovery();
    _emit();
  }

  /// Ferret is in front again: listens again when it did before
  /// [suspend], unless the window it was open for ran out meanwhile.
  Future<void> resume() async {
    if (!_suspended) {
      return;
    }

    _suspended = false;
    final until = _suspendedUntil;
    _suspendedUntil = null;
    if (until != null && !until.isAfter(_clock())) {
      _emit();
      return;
    }

    await _startReceiving(until: until);
  }

  /// Looks for LocalSend devices: asks over multicast, then, when nobody
  /// answers, asks each address on the network.
  Future<void> scan() async {
    if (!isEnabled || _disposed) {
      return;
    }

    _scans++;
    _emit();
    try {
      final identity = await _ready();
      if (identity == null) {
        return;
      }

      if (options.useMulticast) {
        await _startDiscovery();
        await _discovery.announce();
        await Future<void>.delayed(options.multicastWait);
      }

      if (_discovery.peers.isNotEmpty || !options.scanAddresses) {
        return;
      }

      final client = _client;
      final self = _self;
      if (client == null || self == null) {
        return;
      }

      await LegacyScanner(client: client, port: options.port).scan(
        self,
        await LegacyScanner.localNeighbours(),
        onFound: (peer) => _discovery.add(peer.info, peer.address),
      );
    } finally {
      _scans--;
      _releaseDiscoverySoon();
      _emit();
    }
  }

  /// Asks whether a LocalSend device listens at [address] and lists it
  /// when it does, for networks where devices can't find each other.
  Future<bool> findAt(InternetAddress address, {int? port}) async {
    if (!isEnabled || _disposed || await _ready() == null) {
      return false;
    }

    final client = _client;
    final self = _self;
    if (client == null || self == null) {
      return false;
    }

    final peer = await client.probe(
      address,
      self,
      port: port ?? options.port,
    );
    if (peer == null) {
      return false;
    }

    remember(peer.info, peer.address);
    return true;
  }

  /// Lists a LocalSend device that made itself known.
  void remember(LocalSendInfo info, InternetAddress address) =>
      _discovery.add(info, address);

  /// The LocalSend device Drop knows as [deviceId], if it is still
  /// listed.
  LocalSendPeer? peerFor(String deviceId) {
    for (final peer in _discovery.peers) {
      if (LocalSendIds.deviceId(peer.fingerprint) == deviceId) {
        return peer;
      }
    }

    return null;
  }

  /// Sends [files] to the LocalSend device [deviceId], or returns null
  /// when it is no longer listed.
  Transfer? sendFiles(
    String deviceId,
    List<OutgoingFile> files, {
    bool temporary = false,
  }) {
    final peer = peerFor(deviceId);
    if (peer == null) {
      return null;
    }

    return sender.sendFiles(peer, files, temporary: temporary);
  }

  Transfer? sendText(String deviceId, String text) {
    final peer = peerFor(deviceId);
    if (peer == null) {
      return null;
    }

    return sender.sendText(peer, text);
  }

  bool owns(String transferId) =>
      sender.owns(transferId) || receiver.owns(transferId);

  Future<void> cancel(String transferId) async {
    if (sender.owns(transferId)) {
      await sender.cancel(transferId);
      return;
    }

    await receiver.cancel(transferId);
  }

  Future<void> dispose() async {
    _disposed = true;
    _windowTimer?.cancel();
    _discoveryTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    await sender.dispose();
    await receiver.cancelAll();
    await _server?.stop();
    _server = null;
    await _discovery.dispose();
    _hearing?.release();
    _hearing = null;
    _client?.close();
    await _changes.close();
  }

  Future<void> _startReceiving({required DateTime? until}) async {
    if (_disposed || _starting || !isEnabled) {
      return;
    }

    _starting = true;
    _problem = null;
    _emit();
    try {
      final identity = await _ready();
      if (identity == null) {
        _problem = .noIdentity;
        return;
      }

      final server = _server ??= LocalSendServer(
        identity: identity,
        self: _infoFor,
        delegate: receiver,
        port: options.port,
        address: options.bindAddress,
        onRegister: remember,
      );
      await server.start();
      _until = until;
      _armWindow();
      await _startDiscovery();
      if (options.useMulticast) {
        unawaited(_discovery.announce());
      }
    } on SocketException catch (error) {
      printWarning('LocalSend receiving could not start', error.osError);
      _server = null;
      _until = null;
      _problem = .cannotListen;
    } finally {
      _starting = false;
      _emit();
    }
  }

  void _armWindow() {
    _windowTimer?.cancel();
    _windowTimer = null;
    final until = _until;
    if (until == null) {
      return;
    }

    final left = until.difference(_clock());
    _windowTimer = Timer(
      switch (left.isNegative) {
        true => Duration.zero,
        false => left,
      },
      () => unawaited(_closeWindow()),
    );
  }

  /// The window ran out. A transfer still running gets to finish first.
  Future<void> _closeWindow() async {
    if (_server?.isBusy ?? false) {
      _windowTimer = Timer(_busyRecheck, () => unawaited(_closeWindow()));
      return;
    }

    await stopReceiving();
  }

  Future<void> _startDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    if (!options.useMulticast || _discovery.isStarted) {
      return;
    }

    try {
      await _discovery.start();
    } on SocketException catch (error) {
      printWarning('LocalSend discovery could not start', error.osError);
    }

    _followDiscovery();
  }

  void _followDiscovery() {
    if (!_discovery.isStarted || _disposed) {
      _hearing?.release();
      _hearing = null;
      return;
    }

    _hearing ??= multicastNeed?.hold('localsend');
  }

  /// Leaves the multicast group a while after the last scan, unless this
  /// device is receiving.
  void _releaseDiscoverySoon() {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    final listening = _server?.isRunning ?? false;
    if (_disposed || listening || !_discovery.isStarted) {
      return;
    }

    _discoveryTimer = Timer(_discoveryIdle, () {
      if (_server?.isRunning ?? false) {
        return;
      }

      unawaited(_discovery.stop().whenComplete(_followDiscovery));
    });
  }

  Future<LocalSendIdentity?> _ready() async {
    if (_identity case final identity?) {
      return identity;
    }

    try {
      final identity = await _identities.load();
      _identity = identity;
      _client ??= LocalSendClient(identity: identity);
      return identity;
    } on Object catch (error) {
      printWarning('LocalSend identity failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<LocalSendClient> _readyClient() async {
    await _ready();
    final client = _client;
    if (client == null) {
      throw const LocalSendException(.unexpected);
    }

    return client;
  }

  Future<LocalSendInfo> _selfInfo() async {
    await _ready();
    final self = _self;
    if (self == null) {
      throw const LocalSendException(.unexpected);
    }

    return self;
  }

  LocalSendInfo? get _self {
    if (_identity == null) {
      return null;
    }

    return _infoFor(_server?.boundPort ?? _idlePort);
  }

  /// The port to name while nothing listens: the configured one, or
  /// LocalSend's own when a free port is picked at start.
  int get _idlePort => switch (options.port) {
    0 => LocalSendDefaults.port,
    final port => port,
  };

  LocalSendInfo _infoFor(int port) {
    final device = describeSelf();
    return LocalSendInfo(
      alias: device.alias,
      fingerprint: _identity?.fingerprint ?? '',
      deviceModel: device.model,
      deviceType: device.type,
      port: port,
      protocol: LocalSendDefaults.https,
    );
  }

  Future<bool> _registerWith(LocalSendPeer peer) async {
    final client = _client;
    final self = _self;
    if (client == null || self == null) {
      return false;
    }

    await client.register(peer, self);
    return true;
  }

  void _emit() {
    if (_changes.isClosed) {
      return;
    }

    _changes.add(null);
  }
}
