import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/connection/connection.dart';
import 'package:engine/feature/feature.dart';
import 'package:engine/group/group.dart';
import 'package:engine/identity/identity.dart';
import 'package:engine/pairing/pairing.dart';
import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart' hide ForgottenDevice;
import 'package:transport/transport.dart';

/// Runs Ferret on this device: listens, finds and connects to paired devices,
/// pairs new ones, and routes each session's envelopes to the [Feature]s.
class FerretEngine implements FeatureHost {
  FerretEngine._({
    required this.identity,
    required this.trustStore,
    required this.settings,
    required LocalDevice device,
    required List<Feature> features,
    required Discovery discovery,
    required this.preferredPort,
  }) : _device = device,
       _features = {for (final feature in features) feature.id: feature},
       _discovery = discovery,
       _roster = DeviceRoster(trustStore, identity.deviceId);

  static const defaultPort = 47640;
  static const _maxPendingHandshakes = 8;
  static const _pairingTimeout = Duration(seconds: 30);

  /// How long a code comparison waits for each person to answer.
  static const comparisonTimeout = Duration(seconds: 30);

  /// Setting: whether devices paired here are shared with the user's other
  /// devices, and theirs taken in. On unless set to false.
  static const sharePairingsKey = 'pairing.share_with_devices';
  static const _helloTimeout = Duration(seconds: 15);
  static const _nearbyLifetime = Duration(minutes: 2);
  static const _probeTimeout = Duration(seconds: 3);

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
      discovery: discovery ?? CombinedDiscovery.standard(),
      preferredPort: port,
    );
  }

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final SettingsStore settings;

  LocalDevice _device;

  /// What this device tells others about itself.
  LocalDevice get device => _device;
  final int preferredPort;

  final Map<String, Feature> _features;
  final Discovery _discovery;
  final DeviceRoster _roster;
  final StreamController<DeviceJoined> _joins = .broadcast();
  final Map<String, Session> _sessions = {};
  final Map<String, Session> _ready = {};
  final Set<String> _dialing = {};
  final Set<PairingExchange> _pairing = {};
  final Map<String, ({DiscoveredPeer peer, DateTime seen})> _nearby = {};
  final List<PairingOfferHandle> _offers = [];
  final StreamController<List<Session>> _sessionChanges = .broadcast();
  final StreamController<List<DeviceStatus>> _deviceChanges = .broadcast();
  final StreamController<PairingPrompt> _pairingPrompts = .broadcast();
  final StreamController<List<DiscoveredPeer>> _nearbyChanges = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  ServerSocket? _server;
  Presence _presence = Presence(batteryPercent: -1);
  final StreamController<Presence> _presenceChanges = .broadcast();
  bool _featuresStarted = false;
  int _pendingHandshakes = 0;
  bool _running = false;
  Future<void>? _reconnecting;
  bool _reconnectAgain = false;
  final Set<String> _droppedRecently = {};
  final Map<String, int> _drops = {};
  final Map<String, StreamSubscription<bool>> _weakWatches = {};
  DateTime? _startedAt;
  DateTime? _lastHeardOthers;

  /// How long a device that dropped without saying goodbye counts as
  /// coming back: the first four redials (1, 3, 10 and 30 seconds).
  static const _quickRedials = 4;

  /// Redials after a drop. The later ones are minutes apart, for a network
  /// that keeps announcements from arriving, such as a mesh that moved the
  /// device to another access point.
  static const _redialDelays = [1, 3, 10, 30, 60, 120, 300];

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
      DeviceStatus(
        device,
        _ready[device.id],
        isReconnecting:
            _ready[device.id] == null && _droppedRecently.contains(device.id),
      ),
  ];

  /// When this engine last started, or null while it never ran.
  DateTime? get startedAt => _startedAt;

  /// When discovery last heard another Ferret device, paired or not. A
  /// network that keeps devices apart, such as café or hotel Wi-Fi, never
  /// lets one through.
  DateTime? get lastHeardOthers => _lastHeardOthers;

  Stream<List<DeviceStatus>> get deviceChanges => _deviceChanges.stream;

  /// Requests to pair by comparing codes, for the UI to confirm.
  Stream<PairingPrompt> get pairingPrompts => _pairingPrompts.stream;

  /// Devices that joined through another of the user's devices.
  Stream<DeviceJoined> get joins => _joins.stream;

  /// Whether pairings are shared between the user's devices.
  bool get sharesPairings => settings.get<bool>(sharePairingsKey) ?? true;

  /// Turns sharing pairings on or off. Turning it on tells the connected
  /// devices about each other right away.
  Future<void> setSharesPairings(bool shares) async {
    await settings.set(sharePairingsKey, shares);
    if (shares) {
      await _introduceEveryone();
    }
  }

  /// Unpaired Ferret devices seen on the network recently.
  List<DiscoveredPeer> get nearby {
    _dropStaleNearby();
    return [for (final entry in _nearby.values) entry.peer];
  }

  Stream<List<DiscoveredPeer>> get nearbyChanges => _nearbyChanges.stream;

  /// Whether the system keeps Ferret from looking for devices, such as when
  /// the local network permission is off on macOS or iOS.
  bool get isDiscoveryBlocked => switch (_discovery) {
    ActiveDiscovery(:final isBlocked) => isBlocked,
    _ => false,
  };

  /// Looks for nearby devices right now and waits a moment for the answers,
  /// for when the user is watching the list.
  Future<void> scanNearby() async {
    if (!_running) {
      return;
    }

    final discovery = _discovery;
    try {
      switch (discovery) {
        case ActiveDiscovery():
          await discovery.scan();
        default:
          await discovery.announceNow();
      }
    } on Object catch (error) {
      printDebug('Looking for devices failed: $error');
    }

    _dropStaleNearby();
    _nearbyChanges.add(nearby);
  }

  Stream<String> get _departures => switch (_discovery) {
    ActiveDiscovery(:final departures) => departures,
    _ => const Stream.empty(),
  };

  Future<void> start() async {
    if (_running) {
      return;
    }

    _running = true;
    _startedAt = DateTime.now();
    final server = await _bind();
    _server = server;
    _subscriptions
      ..add(server.listen(_onIncomingSocket))
      ..add(_discovery.peers.listen(_onPeer))
      ..add(_departures.listen(_onDeparture))
      ..add(trustStore.changes.listen((_) => _emitDevices()));

    if (!_featuresStarted) {
      _featuresStarted = true;
      for (final feature in _features.values) {
        await feature.start(this);
      }
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

  /// Stops listening, discovery and every session, such as for a pause.
  /// Features keep their state; [start] picks up again.
  Future<void> stop() async {
    if (!_running) {
      return;
    }

    _running = false;
    _droppedRecently.clear();
    await _discovery.stop();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _server?.close();
    _server = null;

    for (final exchange in [..._pairing]) {
      await exchange.close();
    }

    final open = [..._sessions.values];
    for (final session in open) {
      await session.close();
    }
  }

  /// Stops networking and every feature, for when the app quits. Unlike
  /// [stop] (a pause), the engine can't start again afterwards.
  Future<void> shutdown() async {
    await stop();
    if (!_featuresStarted) {
      return;
    }

    for (final feature in _features.values) {
      await feature.stop();
    }
  }

  @override
  Presence get localPresence => _presence;

  @override
  Stream<Presence> get localPresenceChanges => _presenceChanges.stream;

  /// Announces again, such as after the network changed.
  Future<void> refresh() {
    _ownAddresses = null;
    return _discovery.announceNow();
  }

  /// Reconnects right away, for when this device woke from sleep or its
  /// network changed: closes sessions that stopped answering, restarts
  /// discovery on the current interfaces, and dials every paired device that
  /// isn't connected at its last known address. Calls made while one runs
  /// are merged into a single extra run.
  Future<void> reconnectNow({Duration probeTimeout = _probeTimeout}) {
    _ownAddresses = null;
    if (!_running) {
      return Future.value();
    }

    if (_reconnecting case final running?) {
      _reconnectAgain = true;
      return running;
    }

    final run = _reconnectWhileAsked(probeTimeout);
    _reconnecting = run;
    return run;
  }

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
    _presenceChanges.add(presence);
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
      return _requestWithProof(
        PairingExchange(channel),
        proof: proof,
        secret: offer.secret,
        host: host,
        port: offer.port,
      );
    }

    return const PairingFailed(.unreachable);
  }

  /// Pairs with the device at [host] by comparing codes. [onCode] gets the
  /// six digits to show and answers whether the user saw the same ones on
  /// the other device; false gives up. With [expectedDeviceId], such as from
  /// discovery, a different device answering at that address is refused.
  Future<PairingOutcome> pairWithAddress(
    String host,
    int port, {
    required FutureOr<bool> Function(String code) onCode,
    String? expectedDeviceId,
  }) async {
    final SecureChannel channel;
    try {
      channel = await _openChannel(host, port);
    } on Object catch (error) {
      return PairingFailed(.unreachable, '$error');
    }

    final remoteId = await DeviceIdentity.deviceIdFor(channel.remoteStaticKey);
    if (expectedDeviceId != null && expectedDeviceId != remoteId) {
      await channel.close();
      return const PairingFailed(.wrongDevice);
    }

    final exchange = PairingExchange(channel);
    return _whilePairing(
      exchange,
      () =>
          _requestComparison(exchange, onCode: onCode, host: host, port: port),
    );
  }

  /// Keeps track of a pairing under way, so stopping the engine ends it
  /// instead of leaving the other device waiting.
  Future<T> _whilePairing<T>(
    PairingExchange exchange,
    Future<T> Function() pair,
  ) async {
    _pairing.add(exchange);
    try {
      return await pair();
    } finally {
      _pairing.remove(exchange);
    }
  }

  /// Forgets [deviceId] here and tells it to forget this device too. With
  /// [everywhere], the user's other devices forget it as well, the ones
  /// that are away as soon as they connect again.
  Future<void> unpair(String deviceId, {bool everywhere = false}) async {
    final session = _sessions[deviceId];
    final trusted = trustStore[deviceId];
    await trustStore.forget(
      .new(
        id: deviceId,
        at: _afterPairing(trusted),
        by: switch (everywhere && sharesPairings) {
          true => .everywhere,
          false => .here,
        },
      ),
    );
    await trustStore.remove(deviceId);
    await session?.close(.GOODBYE_REASON_UNPAIRED);
    _emitDevices();
    if (everywhere) {
      await _introduceEveryone();
    }
  }

  /// Now, but never before the pairing it undoes: clocks of two devices
  /// differ, and a forgetting dated before the pairing would not hold.
  DateTime _afterPairing(TrustedDevice? trusted) {
    final now = DateTime.now();
    final pairedAt = trusted?.pairedAt;
    if (pairedAt == null || now.isAfter(pairedAt)) {
      return now;
    }

    return pairedAt.add(const Duration(milliseconds: 1));
  }

  /// Renames this device. Nearby devices see it right away; paired ones on
  /// their next connection.
  Future<void> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _device.name) {
      return;
    }

    _device = LocalDevice(
      name: trimmed,
      platform: _device.platform,
      formFactor: _device.formFactor,
      model: _device.model,
      appVersion: _device.appVersion,
    );
    await settings.set('device.name', trimmed);
    if (_running) {
      await _discovery.start(_announce());
    }

    _emitDevices();
  }

  /// Gives the paired [deviceId] a name on this device only, such as
  /// "Work iPhone", or takes it away when [nickname] is null or blank. The
  /// device itself and the user's other devices keep its own name.
  Future<void> renameDevice(String deviceId, String? nickname) =>
      trustStore.rename(deviceId, nickname);

  Future<void> _reconnectWhileAsked(Duration probeTimeout) async {
    try {
      do {
        _reconnectAgain = false;
        await _reconnectOnce(probeTimeout);
      } while (_reconnectAgain && _running);
    } finally {
      _reconnecting = null;
    }
  }

  Future<void> _reconnectOnce(Duration probeTimeout) async {
    await _closeUnresponsive(probeTimeout);
    if (!_running) {
      return;
    }

    await _restartDiscovery();

    final dials = <Future<void>>[];
    for (final trusted in trustStore.devices) {
      if (_sessions[trusted.id] case final session? when !session.isClosed) {
        continue;
      }

      if ((trusted.lastHost, trusted.lastPort) case (
        final host?,
        final port?,
      )) {
        dials.add(_dial(host, port, expectedDeviceId: trusted.id));
      }
    }

    await Future.wait(dials);
  }

  Future<void> _closeUnresponsive(Duration probeTimeout) async {
    final open = [..._ready.values];
    final answers = await Future.wait([
      for (final session in open) session.checkAlive(timeout: probeTimeout),
    ]);

    for (final (index, session) in open.indexed) {
      if (answers[index]) {
        continue;
      }

      printLog('${session.remoteDeviceId} stopped answering; reconnecting');
      await session.close();
    }
  }

  /// Rebinding picks up interfaces that appeared since discovery started,
  /// such as a new Wi-Fi network, so its multicast group is joined there too.
  Future<void> _restartDiscovery() async {
    try {
      await _discovery.stop();
      if (!_running) {
        return;
      }

      await _discovery.start(_announce());
      if (!_running) {
        await _discovery.stop();
      }
    } on Object catch (error) {
      printWarning('Discovery did not restart', error);
    }
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
    unawaited(_onPeerFrom(peer));
  }

  Set<String>? _ownAddresses;

  Future<void> _onPeerFrom(DiscoveredPeer peer) async {
    // A virtual machine behind this computer's NAT (an Android emulator)
    // announces through this computer's own address. Dialing that reaches
    // this device itself, never the announcer.
    if (peer.port == port && peer.deviceId != identity.deviceId) {
      final own = _ownAddresses ??= {
        '127.0.0.1',
        ...await _localAddresses(),
      };
      if (own.contains(peer.host)) {
        return;
      }
    }

    if (peer.deviceId != identity.deviceId) {
      _lastHeardOthers = DateTime.now();
    }

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

  void _onDeparture(String deviceId) {
    if (_nearby.remove(deviceId) == null) {
      return;
    }

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

  /// Pairs from a scanned offer. The proof shows this device saw the
  /// offer's one-time secret and is tied to this very handshake, so nobody
  /// in between can reuse it: scanning is enough, there is no code to
  /// compare.
  Future<PairingOutcome> _requestWithProof(
    PairingExchange exchange, {
    required List<int> proof,
    required List<int> secret,
    required String host,
    required int port,
  }) async {
    final Envelope reply;
    try {
      await exchange.send(
        PairingRequest(device: localDevice, proof: proof),
        expectsReply: true,
      );
      reply = await exchange.next(_pairingTimeout);
    } on TimeoutException {
      await exchange.close();
      return const PairingFailed(.timedOut);
    } on Object catch (error) {
      await exchange.close();
      return PairingFailed(.protocol, '$error');
    }

    final response = PairingExchange.read(reply, PairingResponse.new);
    if (response == null) {
      await exchange.close();
      return const PairingFailed(.protocol, 'Expected a pairing response');
    }

    final failure = await _checkResponse(response, exchange.channel, secret);
    if (failure != null) {
      await exchange.close();
      return failure;
    }

    return _finishRequest(exchange, response.device, host: host, port: port);
  }

  /// Pairs by comparing codes, as the side that asked: commit to a nonce,
  /// get the other side's, reveal, show the code. This device trusts the
  /// other one only when both users agreed.
  Future<PairingOutcome> _requestComparison(
    PairingExchange exchange, {
    required FutureOr<bool> Function(String code) onCode,
    required String host,
    required int port,
  }) async {
    final nonce = PairingCodes.newNonce();
    final PairingChallenge? challenge;
    try {
      await exchange.send(
        PairingRequest(
          device: localDevice,
          commitment: await PairingCodes.commitment(nonce),
          alsoDevices: _alsoDevices(),
        ),
        expectsReply: true,
      );
      final reply = await exchange.next(_pairingTimeout);
      challenge = PairingExchange.read(reply, PairingChallenge.new);
      if (challenge == null) {
        await exchange.close();
        return _refusal(PairingExchange.read(reply, PairingResponse.new));
      }

      await exchange.send(PairingReveal(nonce: nonce));
    } on TimeoutException {
      await exchange.close();
      return const PairingFailed(.timedOut);
    } on Object catch (error) {
      await exchange.close();
      return PairingFailed(.protocol, '$error');
    }

    final code = await PairingCodes.comparisonCode(
      exchange.channel.handshakeHash,
      requesterNonce: nonce,
      answererNonce: challenge.nonce,
    );

    // The user here may give up while the other one still thinks. Hanging
    // up ends the wait for the answer below.
    var cancelled = false;
    final confirmed = Future.sync(() => onCode(code)).then((accepted) async {
      cancelled = !accepted;
      await exchange
          .send(PairingConfirm(accepted: accepted))
          .catchError(
            (
              Object _,
            ) {},
          );
      if (!accepted) {
        await exchange.close();
      }

      return accepted;
    });

    final PairingResponse? response;
    try {
      final reply = await exchange.next(
        comparisonTimeout + _pairingTimeout,
      );
      response = PairingExchange.read(reply, PairingResponse.new);
    } on Object catch (error) {
      await exchange.close();
      return switch ((cancelled, error)) {
        (true, _) => const PairingFailed(.cancelled),
        (_, TimeoutException()) => const PairingFailed(.timedOut),
        _ => PairingFailed(.protocol, '$error'),
      };
    }

    if (response == null ||
        response.result != PairingResult.PAIRING_RESULT_ACCEPTED) {
      await exchange.close();
      return _refusal(response);
    }

    final failure = await _checkResponse(response, exchange.channel, null);
    if (failure != null) {
      await exchange.close();
      return failure;
    }

    final bool accepted;
    try {
      accepted = await confirmed.timeout(comparisonTimeout);
    } on TimeoutException {
      await exchange.close();
      return const PairingFailed(.timedOut);
    }

    if (!accepted) {
      return const PairingFailed(.cancelled);
    }

    return _finishRequest(exchange, response.device, host: host, port: port);
  }

  PairingFailed _refusal(PairingResponse? response) =>
      switch (response?.result) {
        null => const PairingFailed(.protocol, 'Expected a pairing answer'),
        .PAIRING_RESULT_TIMED_OUT => const PairingFailed(.timedOut),
        .PAIRING_RESULT_EXPIRED => const PairingFailed(.expired),
        .PAIRING_RESULT_BAD_PROOF => const PairingFailed(.badProof),
        _ => const PairingFailed(.rejected),
      };

  Future<PairingOutcome> _finishRequest(
    PairingExchange exchange,
    DeviceInfo device, {
    required String host,
    required int port,
  }) async {
    await _trust(device, exchange.channel, host: host, port: port);
    unawaited(
      _openSession(
        exchange.channel,
        exchange.rest,
        remoteId: device.id,
        initiatedByLocal: true,
        host: host,
      ),
    );
    return Paired(device);
  }

  /// The other devices a newly paired one gets connected to, by name.
  List<String> _alsoDevices() => switch (sharesPairings) {
    true => _roster.names,
    false => const [],
  };

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
    final exchange = PairingExchange(channel);
    final Envelope envelope;
    try {
      envelope = await exchange.next(_pairingTimeout);
    } on Object {
      await exchange.close();
      return;
    }

    final request = PairingExchange.read(envelope, PairingRequest.new);
    if (request == null || request.device.id != remoteId) {
      // A device that still trusts this one after it was forgotten here.
      // Telling it so makes it forget too, instead of trying forever.
      printDebug('Device $remoteId is not paired here; telling it so');
      await exchange
          .send(Goodbye(reason: .GOODBYE_REASON_UNPAIRED), as: sessionFeature)
          .catchError((Object _) {});
      await exchange.close();
      return;
    }

    final accepted = await _whilePairing(
      exchange,
      () => switch (request.proof.isEmpty) {
        true => _answerComparison(exchange, envelope, request),
        false => _answerProof(exchange, envelope, request),
      },
    );
    if (!accepted) {
      await exchange.close();
      return;
    }

    await _trust(request.device, channel, host: host);
    await _openSession(
      channel,
      exchange.rest,
      remoteId: remoteId,
      initiatedByLocal: false,
      host: host,
    );
  }

  Future<bool> _respond(
    PairingExchange exchange,
    Envelope request,
    PairingResult result, [
    List<int> proof = const [],
  ]) async {
    try {
      await exchange.send(
        PairingResponse(result: result, device: localDevice, proof: proof),
        replyTo: request,
      );
      return result == PairingResult.PAIRING_RESULT_ACCEPTED;
    } on Object {
      return false;
    }
  }

  /// Answers a request that came from a scanned offer.
  Future<bool> _answerProof(
    PairingExchange exchange,
    Envelope envelope,
    PairingRequest request,
  ) async {
    final hash = exchange.channel.handshakeHash;
    for (final offer in _offers) {
      final expected = await PairingCodes.requestProof(offer.secret, hash);
      if (!PairingCodes.same(expected, request.proof)) {
        continue;
      }

      if (offer.isExpired || offer.isUsed) {
        return _respond(exchange, envelope, .PAIRING_RESULT_EXPIRED);
      }

      offer.complete(request.device);
      return _respond(
        exchange,
        envelope,
        .PAIRING_RESULT_ACCEPTED,
        await PairingCodes.responseProof(offer.secret, hash),
      );
    }

    return _respond(exchange, envelope, .PAIRING_RESULT_BAD_PROOF);
  }

  /// Answers a request to compare codes: holds the requester's commitment,
  /// sends this side's nonce, checks the revealed one, then asks the user.
  /// True only when the user here agreed and the requester's did too.
  Future<bool> _answerComparison(
    PairingExchange exchange,
    Envelope envelope,
    PairingRequest request,
  ) async {
    if (request.commitment.isEmpty) {
      return _respond(exchange, envelope, .PAIRING_RESULT_REJECTED);
    }

    final nonce = PairingCodes.newNonce();
    final PairingReveal? reveal;
    try {
      await exchange.send(PairingChallenge(nonce: nonce), replyTo: envelope);
      reveal = PairingExchange.read(
        await exchange.next(_pairingTimeout),
        PairingReveal.new,
      );
    } on Object {
      return false;
    }

    if (reveal == null ||
        !PairingCodes.same(
          await PairingCodes.commitment(reveal.nonce),
          request.commitment,
        )) {
      return _respond(exchange, envelope, .PAIRING_RESULT_BAD_PROOF);
    }

    final code = await PairingCodes.comparisonCode(
      exchange.channel.handshakeHash,
      requesterNonce: reveal.nonce,
      answererNonce: nonce,
    );
    final prompt = PairingPrompt(
      device: request.device,
      code: code,
      expiresAt: DateTime.now().add(comparisonTimeout),
      alsoDevices: request.alsoDevices.take(DeviceRoster.maxDevices).toList(),
    );

    // The requester's own answer arrives while the user here still looks.
    // A no, or a hang-up, takes the prompt away.
    final confirmed = exchange
        .next(comparisonTimeout + _pairingTimeout)
        .then(
          (reply) =>
              PairingExchange.read(reply, PairingConfirm.new)?.accepted ??
              false,
        )
        .catchError((Object _) => false);
    unawaited(
      confirmed.then((accepted) {
        if (!accepted) {
          prompt.withdraw();
        }
      }),
    );
    final timeout = Timer(comparisonTimeout, prompt.expire);
    _pairingPrompts.add(prompt);
    final answer = await prompt.answer;
    timeout.cancel();

    final result = switch (answer) {
      .accepted => PairingResult.PAIRING_RESULT_ACCEPTED,
      .expired => PairingResult.PAIRING_RESULT_TIMED_OUT,
      .rejected || .withdrawn => PairingResult.PAIRING_RESULT_REJECTED,
    };
    if (!await _respond(exchange, envelope, result)) {
      return false;
    }

    return confirmed;
  }

  Future<void> _trust(
    DeviceInfo info,
    SecureChannel channel, {
    required String host,
    int? port,
  }) async {
    final existing = trustStore[info.id];
    final forgotten = trustStore.forgottenOf(info.id);
    await trustStore.unforget(info.id);
    await trustStore.unforgetDroppedBy();
    await trustStore.save(
      TrustedDevice(
        id: info.id,
        name: info.name,
        platform: info.platform,
        formFactor: info.formFactor,
        publicKey: channel.remoteStaticKey,
        pairedAt: _afterForgetting(forgotten),
        lastSeen: DateTime.now(),
        lastHost: host,
        lastPort: port ?? existing?.lastPort,
        nickname: existing?.nickname,
      ),
    );
    _nearby.remove(info.id);
    _nearbyChanges.add(nearby);
  }

  /// Now, but never before an earlier forgetting of the same device, so
  /// this pairing counts as newer on every device that heard of it.
  DateTime _afterForgetting(ForgottenDevice? forgotten) {
    final now = DateTime.now();
    if (forgotten == null || now.isAfter(forgotten.at)) {
      return now;
    }

    return forgotten.at.add(const Duration(milliseconds: 1));
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
    _droppedRecently.remove(session.remoteDeviceId);
    _watchWeak(session);
    printLog('Connected to ${hello.device.name}');
    for (final feature in _features.values) {
      feature.onSessionOpened(session);
    }

    _emitSessions();
    await _introduceEveryone();
  }

  /// Tells every connected device which other devices this one trusts. It
  /// runs when a device connects and when the list changes, and says the
  /// same thing again otherwise, which changes nothing on the other side.
  Future<void> _introduceEveryone() async {
    if (!sharesPairings) {
      return;
    }

    for (final session in sessions) {
      try {
        await session.send(
          pairingFeature,
          _roster.introductionFor(session.remoteDeviceId),
        );
      } on Object {
        continue;
      }
    }
  }

  Future<void> _onIntroduce(Session session, Envelope envelope) async {
    final introduce = payloadOf(envelope, Introduce.new);
    final introducer = trustStore[session.remoteDeviceId];
    if (introduce == null || introducer == null || !sharesPairings) {
      return;
    }

    final changes = await _roster.apply(introduce, introducer);
    for (final deviceId in changes.removed) {
      await _sessions[deviceId]?.close(.GOODBYE_REASON_UNPAIRED);
    }

    for (final joined in changes.joined) {
      printLog(
        '${joined.device.name} joined through ${joined.introducer.name}',
      );
      _nearby.remove(joined.device.id);
      _joins.add(joined);
      if ((joined.device.lastHost, joined.device.lastPort) case (
        final host?,
        final port?,
      )) {
        unawaited(_dial(host, port, expectedDeviceId: joined.device.id));
      }
    }

    if (changes.removed.isEmpty && changes.joined.isEmpty) {
      return;
    }

    _nearbyChanges.add(nearby);
    _emitDevices();
    await _introduceEveryone();
  }

  Future<void> _route(Session session, Envelope envelope) async {
    if (envelope.feature == sessionFeature) {
      return;
    }

    if (envelope.feature == pairingFeature) {
      await _onIntroduce(session, envelope);
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
      unawaited(_weakWatches.remove(session.remoteDeviceId)?.cancel());
      if (_running && session.remoteGoodbye == null) {
        _droppedRecently.add(session.remoteDeviceId);
      }

      for (final feature in _features.values) {
        feature.onSessionClosed(session);
      }

      _emitSessions();
    }

    switch (session.remoteGoodbye) {
      case .GOODBYE_REASON_UNPAIRED:
        unawaited(_onUnpairedBy(session.remoteDeviceId));
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

  /// The other device forgot this one. Forgetting it back, here only, keeps
  /// another of the user's devices from introducing it again.
  Future<void> _onUnpairedBy(String deviceId) async {
    final trusted = trustStore[deviceId];
    if (trusted == null) {
      return;
    }

    await trustStore.forget(
      .new(id: deviceId, at: _afterPairing(trusted), by: .them),
    );
    await trustStore.remove(deviceId);
  }

  /// Only the newest drop of a device redials; an older run that wakes up
  /// after the device came back and dropped again leaves it to the new one.
  Future<void> _reconnect(String deviceId) async {
    final drop = (_drops[deviceId] ?? 0) + 1;
    _drops[deviceId] = drop;
    try {
      for (final (attempt, delay) in _redialDelays.indexed) {
        if (attempt == _quickRedials) {
          _settleDrop(deviceId);
        }

        await Future<void>.delayed(Duration(seconds: delay));
        if (!_running ||
            _drops[deviceId] != drop ||
            _sessions.containsKey(deviceId)) {
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
    } finally {
      if (_drops[deviceId] == drop) {
        _settleDrop(deviceId);
      }
    }
  }

  /// The quick redials are over: the device reads as offline from here.
  void _settleDrop(String deviceId) {
    if (!_droppedRecently.remove(deviceId)) {
      return;
    }

    _emitDevices();
  }

  void _watchWeak(Session session) {
    unawaited(_weakWatches.remove(session.remoteDeviceId)?.cancel());
    _weakWatches[session.remoteDeviceId] = session.weakChanges.listen(
      (_) => _emitDevices(),
    );
  }

  void _emitSessions() {
    _sessionChanges.add(sessions);
    _emitDevices();
  }

  void _emitDevices() => _deviceChanges.add(devices);
}
