import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:core/core.dart';
import 'package:engine/connection/connection.dart';
import 'package:engine/feature/feature.dart';
import 'package:engine/identity/identity.dart';
import 'package:engine/pairing/pairing.dart';
import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Feature id of pairing messages.
const pairingFeature = 'pairing';

/// Runs Ferret on this device: listens, finds and connects to paired devices,
/// pairs new ones, and routes each session's envelopes to the [Feature]s.
class FerretEngine implements FeatureHost {
  FerretEngine._({
    required this.identity,
    required this.trustStore,
    required this.settings,
    required this.device,
    required List<Feature> features,
    required Discovery discovery,
    required this.preferredPort,
  }) : _features = {for (final feature in features) feature.id: feature},
       _discovery = discovery;

  static const defaultPort = 47640;
  static const _maxPendingHandshakes = 8;
  static const _pairingTimeout = Duration(seconds: 30);
  static const _comparisonTimeout = Duration(minutes: 2);
  static const _helloTimeout = Duration(seconds: 15);
  static const _nearbyLifetime = Duration(minutes: 2);

  static Future<FerretEngine> create({
    required SecretStore secrets,
    required SettingsStore settings,
    required LocalDevice device,
    List<Feature> features = const [],
    Discovery? discovery,
    int port = defaultPort,
  }) async {
    final identity = await DeviceIdentity.loadOrCreate(secrets);
    final trustStore = await TrustStore.open(secrets);
    return FerretEngine._(
      identity: identity,
      trustStore: trustStore,
      settings: settings,
      device: device,
      features: features,
      discovery: discovery ?? MulticastDiscovery(),
      preferredPort: port,
    );
  }

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final SettingsStore settings;

  final LocalDevice device;
  final int preferredPort;

  final Map<String, Feature> _features;
  final Discovery _discovery;
  final Map<String, Session> _sessions = {};
  final Map<String, Session> _ready = {};
  final Set<String> _dialing = {};
  final Map<String, ({DiscoveredPeer peer, DateTime seen})> _nearby = {};
  final List<PairingOfferHandle> _offers = [];
  final StreamController<List<Session>> _sessionChanges = .broadcast();
  final StreamController<List<DeviceStatus>> _deviceChanges = .broadcast();
  final StreamController<PairingPrompt> _pairingPrompts = .broadcast();
  final StreamController<List<DiscoveredPeer>> _nearbyChanges = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  ServerSocket? _server;
  Presence _presence = Presence(batteryPercent: -1);
  int _pendingHandshakes = 0;
  bool _running = false;

  /// The TCP port this device listens on, once started.
  int get port => _server?.port ?? preferredPort;

  bool get isRunning => _running;

  @override
  DeviceInfo get localDevice => device.toInfo(identity.deviceId);

  List<Feature> get features => List.unmodifiable(_features.values);

  T? feature<T extends Feature>() {
    for (final feature in _features.values) {
      if (feature is T) {
        return feature;
      }
    }

    return null;
  }

  @override
  List<Session> get sessions => List.unmodifiable(_ready.values);

  @override
  Session? sessionFor(String deviceId) => _ready[deviceId];

  @override
  Stream<List<Session>> get sessionChanges => _sessionChanges.stream;

  /// Paired devices with their connection state.
  List<DeviceStatus> get devices => [
    for (final device in trustStore.devices)
      DeviceStatus(device, _ready[device.id]),
  ];

  Stream<List<DeviceStatus>> get deviceChanges => _deviceChanges.stream;

  /// Requests to pair by comparing codes, for the UI to confirm.
  Stream<PairingPrompt> get pairingPrompts => _pairingPrompts.stream;

  /// Unpaired Ferret devices seen on the network recently.
  List<DiscoveredPeer> get nearby {
    _dropStaleNearby();
    return [for (final entry in _nearby.values) entry.peer];
  }

  Stream<List<DiscoveredPeer>> get nearbyChanges => _nearbyChanges.stream;

  Future<void> start() async {
    if (_running) {
      return;
    }

    _running = true;
    _server = await _bind();
    _subscriptions
      ..add(_server!.listen(_onIncomingSocket))
      ..add(_discovery.peers.listen(_onPeer))
      ..add(trustStore.changes.listen((_) => _emitDevices()));

    for (final feature in _features.values) {
      await feature.start(this);
    }

    await _discovery.start(_announce());
    printLog(
      'Ferret ${DeviceIdentity.format(identity.deviceId)} listening on port $port',
    );

    for (final trusted in trustStore.devices) {
      if ((trusted.lastHost, trusted.lastPort) case (
        final host?,
        final port?,
      )) {
        unawaited(_dial(host, port, expectedDeviceId: trusted.id));
      }
    }
  }

  Future<void> stop() async {
    if (!_running) {
      return;
    }

    _running = false;
    await _discovery.stop();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _server?.close();
    _server = null;

    final open = [..._sessions.values];
    for (final session in open) {
      await session.close();
    }

    for (final feature in _features.values) {
      await feature.stop();
    }
  }

  /// Announces again, such as after the network changed.
  Future<void> refresh() => _discovery.announceNow();

  /// Connects to a device by address, for networks without multicast.
  Future<void> connect(String host, int port) => _dial(host, port);

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {
    for (final session in sessions) {
      if (!session.supports(featureId)) {
        continue;
      }

      try {
        await session.send(featureId, message);
      } on Object catch (error) {
        printWarning(
          'Broadcast of $featureId to ${session.remoteDeviceId} failed',
          error,
        );
      }
    }
  }

  /// Tells paired devices whether someone is using this one right now.
  Future<void> updatePresence(Presence presence) async {
    _presence = presence;
    for (final session in sessions) {
      try {
        await session.sendPresence(presence);
      } on Object {
        continue;
      }
    }
  }

  /// Creates a one-time pairing offer to show as a QR code or link.
  Future<PairingOfferHandle> createPairingOffer({
    Duration lifetime = const Duration(minutes: 5),
  }) async {
    _offers.removeWhere((offer) => offer.isExpired || offer.isUsed);

    final hosts = await _localAddresses();
    final expiresAt = DateTime.now().add(lifetime).millisecondsSinceEpoch;
    final offer = PairingOffer(
      protocolVersion: protocolVersion,
      deviceId: identity.deviceId,
      name: device.name,
      platform: device.platform,
      hosts: hosts,
      port: port,
      staticPublicKey: identity.publicKey,
      secret: PairingCodes.newSecret(),
      expiresAtMs: Int64(expiresAt),
    );

    final handle = PairingOfferHandle(offer, PairingOfferHandle.uriFor(offer));
    _offers.add(handle);
    return handle;
  }

  /// Pairs with the device that shows [offer], such as from a scanned QR code.
  Future<PairingOutcome> pairWithOffer(PairingOffer offer) async {
    if (DateTime.now().millisecondsSinceEpoch > offer.expiresAtMs.toInt()) {
      return const PairingFailed(.expired);
    }

    for (final host in offer.hosts) {
      final SecureChannel channel;
      try {
        channel = await _openChannel(host, offer.port);
      } on Object {
        continue;
      }

      if (!PairingCodes.same(channel.remoteStaticKey, offer.staticPublicKey)) {
        await channel.close();
        return const PairingFailed(.wrongDevice);
      }

      final proof = await PairingCodes.requestProof(
        offer.secret,
        channel.handshakeHash,
      );
      return _requestPairing(
        channel,
        proof: proof,
        secret: offer.secret,
        host: host,
        port: offer.port,
      );
    }

    return const PairingFailed(.unreachable);
  }

  /// Pairs with the device at [host] by comparing codes. [onCode] gets the
  /// six digits to show while the other device's user confirms.
  Future<PairingOutcome> pairWithAddress(
    String host,
    int port, {
    required void Function(String code) onCode,
  }) async {
    final SecureChannel channel;
    try {
      channel = await _openChannel(host, port);
    } on Object catch (error) {
      return PairingFailed(.unreachable, '$error');
    }

    onCode(await PairingCodes.comparisonCode(channel.handshakeHash));
    return _requestPairing(channel, proof: const [], host: host, port: port);
  }

  /// Forgets [deviceId] here and tells it to forget this device too.
  Future<void> unpair(String deviceId) async {
    final session = _sessions[deviceId];
    await trustStore.remove(deviceId);
    await session?.close(.GOODBYE_REASON_UNPAIRED);
    _emitDevices();
  }

  /// Renames this device for others; they see it on the next connection.
  Future<void> rename(String name) async {
    await settings.set('device.name', name);
  }

  Future<ServerSocket> _bind() async {
    try {
      return await ServerSocket.bind(InternetAddress.anyIPv4, preferredPort);
    } on SocketException {
      printWarning('Port $preferredPort is taken; using a free one');
      return ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
  }

  Announce _announce() => Announce(
    protocolVersion: protocolVersion,
    deviceId: identity.deviceId,
    name: device.name,
    platform: device.platform,
    formFactor: device.formFactor,
    port: port,
  );

  Hello _hello() => Hello(
    device: localDevice,
    features: [
      for (final feature in _features.values)
        if (feature.isAvailable) feature.support,
    ],
    listenPort: port,
  );

  Future<List<String>> _localAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return [
      for (final interface in interfaces)
        for (final address in interface.addresses)
          if (!address.isLoopback && !address.isLinkLocal) address.address,
    ];
  }

  Future<SecureChannel> _openChannel(String host, int port) async {
    final connection = await SocketConnection.connect(host, port);
    return SecureChannel.initiate(connection, identity.keyPair);
  }

  void _onPeer(DiscoveredPeer peer) {
    if (trustStore.isTrusted(peer.deviceId)) {
      if (!_sessions.containsKey(peer.deviceId)) {
        unawaited(_dial(peer.host, peer.port, expectedDeviceId: peer.deviceId));
      }

      return;
    }

    _nearby[peer.deviceId] = (peer: peer, seen: DateTime.now());
    _dropStaleNearby();
    _nearbyChanges.add(nearby);
  }

  void _dropStaleNearby() {
    final cutoff = DateTime.now().subtract(_nearbyLifetime);
    _nearby.removeWhere(
      (deviceId, entry) =>
          entry.seen.isBefore(cutoff) || trustStore.isTrusted(deviceId),
    );
  }

  Future<void> _dial(String host, int port, {String? expectedDeviceId}) async {
    if (!_running) {
      return;
    }

    final key = expectedDeviceId ?? '$host:$port';
    if (!_dialing.add(key)) {
      return;
    }

    try {
      final channel = await _openChannel(host, port);
      final remoteId = await DeviceIdentity.deviceIdFor(
        channel.remoteStaticKey,
      );
      if (!_isTrustedKey(remoteId, channel.remoteStaticKey)) {
        printWarning('Device at $host:$port is not paired; closing');
        await channel.close();
        return;
      }

      await _openSession(
        channel,
        channel.messages,
        remoteId: remoteId,
        initiatedByLocal: true,
        host: host,
      );
    } on Object catch (error) {
      printDebug('Could not reach $host:$port: $error');
    } finally {
      _dialing.remove(key);
    }
  }

  bool _isTrustedKey(String deviceId, List<int> publicKey) {
    final trusted = trustStore[deviceId];
    if (trusted == null) {
      return false;
    }

    return PairingCodes.same(trusted.publicKey, publicKey);
  }

  Future<void> _onIncomingSocket(Socket socket) async {
    if (_pendingHandshakes >= _maxPendingHandshakes) {
      socket.destroy();
      return;
    }

    _pendingHandshakes++;
    final connection = SocketConnection(socket);
    final SecureChannel channel;
    try {
      channel = await SecureChannel.respond(connection, identity.keyPair);
    } on Object catch (error) {
      printDebug('Handshake from ${connection.remoteAddress} failed: $error');
      return;
    } finally {
      _pendingHandshakes--;
    }

    final remoteId = await DeviceIdentity.deviceIdFor(channel.remoteStaticKey);
    if (_isTrustedKey(remoteId, channel.remoteStaticKey)) {
      await _openSession(
        channel,
        channel.messages,
        remoteId: remoteId,
        initiatedByLocal: false,
        host: connection.remoteHost,
      );
      return;
    }

    await _answerPairing(channel, remoteId, connection.remoteHost);
  }

  Future<PairingOutcome> _requestPairing(
    SecureChannel channel, {
    required List<int> proof,
    required String host,
    required int port,
    List<int>? secret,
  }) async {
    final queue = StreamQueue(channel.messages);
    final request = Envelope(
      id: Int64(1),
      feature: pairingFeature,
      type: PairingRequest().payloadType,
      payload: PairingRequest(device: localDevice, proof: proof).toPayload(),
      expectsReply: true,
    );

    final Envelope reply;
    try {
      await channel.send(request.writeToBuffer());
      final timeout = switch (proof.isEmpty) {
        true => _comparisonTimeout,
        false => _pairingTimeout,
      };
      reply = Envelope.fromBuffer(await queue.next.timeout(timeout));
    } on TimeoutException {
      await channel.close();
      return const PairingFailed(.timedOut);
    } on Object catch (error) {
      await channel.close();
      return PairingFailed(.protocol, '$error');
    }

    final response = unpackPayload(
      type: reply.type,
      payload: reply.payload,
      create: PairingResponse.new,
    );
    if (response == null) {
      await channel.close();
      return const PairingFailed(.protocol, 'Expected a pairing response');
    }

    final failure = await _checkResponse(response, channel, secret);
    if (failure != null) {
      await channel.close();
      return failure;
    }

    await _trust(response.device, channel, host: host, port: port);
    unawaited(
      _openSession(
        channel,
        queue.rest,
        remoteId: response.device.id,
        initiatedByLocal: true,
        host: host,
      ),
    );
    return Paired(response.device);
  }

  Future<PairingFailed?> _checkResponse(
    PairingResponse response,
    SecureChannel channel,
    List<int>? secret,
  ) async {
    switch (response.result) {
      case .PAIRING_RESULT_ACCEPTED:
        break;
      case .PAIRING_RESULT_EXPIRED:
        return const PairingFailed(.expired);
      case .PAIRING_RESULT_BAD_PROOF:
        return const PairingFailed(.badProof);
      default:
        return const PairingFailed(.rejected);
    }

    final remoteId = await DeviceIdentity.deviceIdFor(channel.remoteStaticKey);
    if (response.device.id != remoteId) {
      return const PairingFailed(.wrongDevice);
    }

    if (secret == null) {
      return null;
    }

    final expected = await PairingCodes.responseProof(
      secret,
      channel.handshakeHash,
    );
    if (!PairingCodes.same(expected, response.proof)) {
      return const PairingFailed(.badProof);
    }

    return null;
  }

  Future<void> _answerPairing(
    SecureChannel channel,
    String remoteId,
    String host,
  ) async {
    final queue = StreamQueue(channel.messages);
    final Envelope envelope;
    try {
      envelope = Envelope.fromBuffer(await queue.next.timeout(_pairingTimeout));
    } on Object {
      await channel.close();
      return;
    }

    final request = unpackPayload(
      type: envelope.type,
      payload: envelope.payload,
      create: PairingRequest.new,
    );
    if (envelope.feature != pairingFeature ||
        request == null ||
        request.device.id != remoteId) {
      printWarning(
        'Unpaired device $remoteId sent something other than a pairing request',
      );
      await channel.close();
      return;
    }

    final (result, proof) = await _decidePairing(request, channel);
    final response = PairingResponse(
      result: result,
      device: localDevice,
      proof: proof,
    );
    try {
      await channel.send(
        Envelope(
          id: Int64(1),
          replyTo: envelope.id,
          feature: pairingFeature,
          type: response.payloadType,
          payload: response.toPayload(),
        ).writeToBuffer(),
      );
    } on Object {
      await channel.close();
      return;
    }

    if (result != .PAIRING_RESULT_ACCEPTED) {
      await channel.close();
      return;
    }

    await _trust(request.device, channel, host: host);
    await _openSession(
      channel,
      queue.rest,
      remoteId: remoteId,
      initiatedByLocal: false,
      host: host,
    );
  }

  Future<(PairingResult, List<int>)> _decidePairing(
    PairingRequest request,
    SecureChannel channel,
  ) async {
    if (request.proof.isEmpty) {
      final code = await PairingCodes.comparisonCode(channel.handshakeHash);
      final prompt = PairingPrompt(device: request.device, code: code);
      _pairingPrompts.add(prompt);

      final accepted = await prompt.decision.timeout(
        _comparisonTimeout,
        onTimeout: () => false,
      );
      final result = switch (accepted) {
        true => PairingResult.PAIRING_RESULT_ACCEPTED,
        false => PairingResult.PAIRING_RESULT_REJECTED,
      };
      return (result, const <int>[]);
    }

    for (final offer in _offers) {
      final expected = await PairingCodes.requestProof(
        offer.secret,
        channel.handshakeHash,
      );
      if (!PairingCodes.same(expected, request.proof)) {
        continue;
      }

      if (offer.isExpired || offer.isUsed) {
        return (PairingResult.PAIRING_RESULT_EXPIRED, const <int>[]);
      }

      offer.complete(request.device);
      return (
        PairingResult.PAIRING_RESULT_ACCEPTED,
        await PairingCodes.responseProof(offer.secret, channel.handshakeHash),
      );
    }

    return (PairingResult.PAIRING_RESULT_BAD_PROOF, const <int>[]);
  }

  Future<void> _trust(
    DeviceInfo info,
    SecureChannel channel, {
    required String host,
    int? port,
  }) async {
    final existing = trustStore[info.id];
    await trustStore.save(
      TrustedDevice(
        id: info.id,
        name: info.name,
        platform: info.platform,
        formFactor: info.formFactor,
        publicKey: channel.remoteStaticKey,
        pairedAt: existing?.pairedAt ?? DateTime.now(),
        lastSeen: DateTime.now(),
        lastHost: host,
        lastPort: port ?? existing?.lastPort,
      ),
    );
    _nearby.remove(info.id);
    _nearbyChanges.add(nearby);
  }

  Future<void> _openSession(
    SecureChannel channel,
    Stream<List<int>> messages, {
    required String remoteId,
    required bool initiatedByLocal,
    required String host,
  }) async {
    final initiatorId = switch (initiatedByLocal) {
      true => identity.deviceId,
      false => remoteId,
    };

    if (_sessions[remoteId] case final existing? when !existing.isClosed) {
      final keepNew =
          existing.initiatorDeviceId == initiatorId ||
          initiatorId.compareTo(existing.initiatorDeviceId) < 0;
      if (!keepNew) {
        await channel.close();
        return;
      }

      await existing.close(.GOODBYE_REASON_DUPLICATE);
    }

    final session = Session(
      channel: channel,
      messages: messages,
      remoteDeviceId: remoteId,
      initiatedByLocal: initiatedByLocal,
      initiatorDeviceId: initiatorId,
    );
    _sessions[remoteId] = session;
    unawaited(session.closed.then((_) => _onSessionClosed(session, host)));

    final hello = session.incoming
        .where((envelope) => envelope.feature == sessionFeature)
        .map(
          (envelope) => unpackPayload(
            type: envelope.type,
            payload: envelope.payload,
            create: Hello.new,
          ),
        )
        .firstWhere((hello) => hello != null)
        .timeout(_helloTimeout);
    session.incoming.listen((envelope) => unawaited(_route(session, envelope)));

    try {
      await session.sendHello(_hello());
      await session.sendPresence(_presence);
      final remoteHello = await hello;
      if (remoteHello == null) {
        throw const SessionClosedException();
      }

      session.remoteHello = remoteHello;
      await _onHello(session, remoteHello, host);
    } on Object catch (error) {
      printDebug('Session with $remoteId did not start: $error');
      await session.close();
    }
  }

  Future<void> _onHello(Session session, Hello hello, String host) async {
    if (session.isClosed) {
      return;
    }

    final trusted = trustStore[session.remoteDeviceId];
    if (trusted != null) {
      await trustStore.save(
        trusted.copyWith(
          name: hello.device.name,
          platform: hello.device.platform,
          formFactor: hello.device.formFactor,
          lastSeen: DateTime.now(),
          lastHost: host,
          lastPort: hello.listenPort,
        ),
      );
    }

    _ready[session.remoteDeviceId] = session;
    printLog('Connected to ${hello.device.name}');
    for (final feature in _features.values) {
      feature.onSessionOpened(session);
    }

    _emitSessions();
  }

  Future<void> _route(Session session, Envelope envelope) async {
    if (envelope.feature == sessionFeature) {
      return;
    }

    final feature = _features[envelope.feature];
    if (feature == null || !feature.isAvailable) {
      if (envelope.expectsReply) {
        await session
            .replyError(envelope, .ERROR_CODE_UNSUPPORTED, envelope.feature)
            .catchError((Object _) {});
      }

      return;
    }

    try {
      final reply = await feature.onEnvelope(session, envelope);
      if (reply != null && envelope.expectsReply) {
        await session.reply(envelope, reply);
      }
    } on Object catch (error, stackTrace) {
      printError(
        'Feature ${feature.id} failed on ${envelope.type}',
        error,
        stackTrace,
      );
      if (envelope.expectsReply) {
        await session
            .replyError(envelope, .ERROR_CODE_INTERNAL)
            .catchError((Object _) {});
      }
    }
  }

  void _onSessionClosed(Session session, String host) {
    if (_sessions[session.remoteDeviceId] == session) {
      _sessions.remove(session.remoteDeviceId);
    }

    final wasReady = _ready[session.remoteDeviceId] == session;
    if (wasReady) {
      _ready.remove(session.remoteDeviceId);
      for (final feature in _features.values) {
        feature.onSessionClosed(session);
      }

      _emitSessions();
    }

    switch (session.remoteGoodbye) {
      case .GOODBYE_REASON_UNPAIRED:
        unawaited(trustStore.remove(session.remoteDeviceId));
        return;
      case .GOODBYE_REASON_DUPLICATE:
        return;
      default:
        break;
    }

    if (!_running || !wasReady) {
      return;
    }

    unawaited(_reconnect(session.remoteDeviceId));
  }

  Future<void> _reconnect(String deviceId) async {
    for (final delay in const [1, 3, 10, 30]) {
      await Future<void>.delayed(Duration(seconds: delay));
      if (!_running || _sessions.containsKey(deviceId)) {
        return;
      }

      final trusted = trustStore[deviceId];
      if (trusted == null) {
        return;
      }

      if ((trusted.lastHost, trusted.lastPort) case (
        final host?,
        final port?,
      )) {
        await _dial(host, port, expectedDeviceId: deviceId);
      }
    }
  }

  void _emitSessions() {
    _sessionChanges.add(sessions);
    _emitDevices();
  }

  void _emitDevices() => _deviceChanges.add(devices);
}
