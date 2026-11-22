import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/access/access.dart';
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
    required VpnAddresses vpnFilter,
    required Future<List<String>> Function() vpnAddressSource,
    required List<Duration> vpnDelays,
    required SameAccount sameAccount,
    required Duration justPaired,
    required Duration groupRequestLifetime,
    required LocalNetworkSource? networks,
    required Future<Set<String>> Function()? ownAddresses,
    required this.multicastNeed,
  }) : _device = device,
       _networkSource = networks,
       _ownAddressOverride = ownAddresses,
       _justPaired = justPaired,
       _groupRequestLifetime = groupRequestLifetime,
       _sameAccount = sameAccount,
       _vpnFilter = vpnFilter,
       _vpnAddressSource = vpnAddressSource,
       _features = {for (final feature in features) feature.id: feature},
       _discovery = discovery {
    _vpnReacher = VpnReacher(attempt: _reachOverVpn, delays: vpnDelays);
  }

  static const defaultPort = 47640;

  /// How many ports after the preferred one's neighbour are tried when it
  /// is taken (47642 to 47649 for the default). 47641 is discovery's.
  static const fallbackPortCount = 8;

  /// The ports tried in order: [preferred], then the fallback range. Port 0
  /// (any free port) has no range.
  static List<int> candidatePorts(int preferred) => [
    preferred,
    if (preferred != 0)
      for (var offset = 2; offset < 2 + fallbackPortCount; offset++)
        preferred + offset,
  ];
  static const _maxPendingHandshakes = 8;

  /// Devices that aren't paired may only ask to pair: a few at a time, in
  /// short messages, so a stranger on the network can't fill memory.
  static const _maxStrangers = 4;
  static const _strangerMessageLimit = 64 * 1024;
  static const _pairingTimeout = Duration(seconds: 30);

  /// How long a code comparison waits for each person to answer.
  static const comparisonTimeout = Duration(seconds: 30);

  /// Setting: whether devices paired here are shared with the user's other
  /// devices, and theirs taken in. On unless set to false.
  static const sharePairingsKey = 'pairing.share_with_devices';

  /// Setting: whether this device announces itself on every network, not
  /// only where it met a paired device. Off unless set to true.
  static const alwaysVisibleKey = 'discovery.always_visible';
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
    VpnAddresses vpnFilter = const VpnAddresses(),
    Future<List<String>> Function() vpnAddressSource =
        VpnAddresses.ofThisDevice,
    List<Duration> vpnDelays = VpnReacher.defaultDelays,
    SameAccount? sameAccount,
    Duration justPaired = defaultJustPaired,
    Duration groupRequestLifetime = defaultGroupRequestLifetime,
    LocalNetworkSource? networks,
    Future<Set<String>> Function()? ownAddresses,
    MulticastNeed? multicastNeed,
    String? machineId,
  }) async {
    await IdentityHome.settle(
      secrets: secrets,
      settings: settings,
      machineId: machineId,
    );
    // Side by side: on a slow phone each Keystore read is a trip to the
    // secure hardware, and the key maths can run while it is away.
    final trustLoad = TrustStore.open(secrets)..ignore();
    final identity = await DeviceIdentity.loadOrCreate(secrets);
    final trustStore = await trustLoad;
    return FerretEngine._(
      identity: identity,
      trustStore: trustStore,
      settings: settings,
      device: device,
      features: features,
      discovery: discovery ?? CombinedDiscovery.standard(),
      preferredPort: port,
      vpnFilter: vpnFilter,
      vpnAddressSource: vpnAddressSource,
      vpnDelays: vpnDelays,
      sameAccount: sameAccount ?? SameAccount(),
      justPaired: justPaired,
      groupRequestLifetime: groupRequestLifetime,
      networks: networks,
      ownAddresses: ownAddresses,
      multicastNeed: multicastNeed ?? MulticastNeed(),
    );
  }

  /// A device paired by hand here this recently brings its other devices
  /// along without a question: the user is pairing right now, and the
  /// pairing prompt named them.
  static const defaultJustPaired = Duration(minutes: 2);

  /// How long a [GroupRequest] waits for an answer.
  static const defaultGroupRequestLifetime = Duration(hours: 24);

  /// Removals the user turned down, by device id, with the time of the
  /// removal, so the same word isn't asked about again.
  static const keptRemovalsKey = 'pairing.keptRemovals';

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final SettingsStore settings;

  /// Which features each paired device may use with this one.
  late final DeviceAccess access = DeviceAccess(settings);

  LocalDevice _device;

  /// What this device tells others about itself.
  LocalDevice get device => _device;
  final int preferredPort;

  /// Whether this device needs to hear the network now: Android keeps its
  /// Wi-Fi multicast lock only while it does. Screens that list devices
  /// nearby hold it; the engine adds paired devices that aren't connected.
  final MulticastNeed multicastNeed;

  final Map<String, Feature> _features;
  final VpnAddresses _vpnFilter;
  final Future<List<String>> Function() _vpnAddressSource;
  late final VpnReacher _vpnReacher;
  final Discovery _discovery;
  final LocalNetworkSource? _networkSource;
  final Future<Set<String>> Function()? _ownAddressOverride;

  Future<Set<String>> _ownAddressSource() =>
      (_ownAddressOverride ?? _systemOwnAddresses)();
  late final KnownNetworks _knownNetworks = KnownNetworks(
    settings,
    salt: identity.deviceId,
    source: _networkSource,
  );
  int _visibleHolds = 0;
  bool _onKnownNetwork = false;
  late final DeviceRoster _roster = DeviceRoster(
    trustStore,
    identity.deviceId,
    beforeJoin: _inheritAccess,
  );
  final StreamController<DeviceJoined> _joins = .broadcast();
  final PairingCooldown _pairingCooldown = PairingCooldown();
  final Duration _justPaired;
  final Duration _groupRequestLifetime;
  final Map<String, GroupRequest> _groupRequests = {};
  final Map<String, Timer> _groupRequestTimers = {};
  final StreamController<List<GroupRequest>> _groupRequestChanges =
      .broadcast();
  final Map<String, Session> _sessions = {};
  final Map<String, Session> _ready = {};
  final Map<Session, List<Feature>> _openedFeatures = {};
  final Set<String> _dialing = {};
  final Set<PairingExchange> _pairing = {};
  final Map<String, ({DiscoveredPeer peer, DateTime seen})> _nearby = {};

  /// When each paired device last announced itself here since its last
  /// session ended.
  final Map<String, DateTime> _heardPaired = {};
  final List<PairingOfferHandle> _offers = [];
  final StreamController<List<Session>> _sessionChanges = .broadcast();
  final StreamController<List<DeviceStatus>> _deviceChanges = .broadcast();
  final StreamController<PairingPrompt> _pairingPrompts = .broadcast();
  final StreamController<List<DiscoveredPeer>> _nearbyChanges = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Set<String> _otherAccounts = {};
  final SameAccount _sameAccount;

  /// Ferret this same account runs here, such as its ferret-cli, and the
  /// ones still being checked: never another account.
  final Set<String> _ownAccount = {};
  final StreamController<void> _otherAccountsChanges = .broadcast();

  ServerSocket? _server;

  /// The port [_server] was bound to, kept so it can still be read while a
  /// stop closes the socket under a start that hasn't finished.
  int? _boundPort;
  Presence _presence = Presence(batteryPercent: -1);
  final StreamController<Presence> _presenceChanges = .broadcast();
  bool _featuresStarted = false;
  int _pendingHandshakes = 0;
  int _strangers = 0;
  bool _running = false;
  Future<void>? _reconnecting;
  bool _reconnectAgain = false;
  final Set<String> _droppedRecently = {};
  final Map<String, VersionMismatch> _mismatches = {};
  final Map<String, int> _drops = {};
  final Map<String, StreamSubscription<bool>> _weakWatches = {};
  final Map<String, StreamSubscription<Presence>> _presenceWatches = {};
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
  int get port => _boundPort ?? preferredPort;

  /// Whether the preferred port was taken, such as by Ferret in another
  /// account on this computer, so this one listens on another.
  bool get usesFallbackPort =>
      _boundPort != null && preferredPort != 0 && port != preferredPort;

  /// Ferret in other accounts on this computer, by device id: they
  /// announce from this computer's own address with its platform. Several
  /// people sharing one computer each get their own Ferret. What this
  /// account runs itself, such as its ferret-cli, never counts (see
  /// [SameAccount]).
  Set<String> get otherAccountsHere => Set.unmodifiable(_otherAccounts);

  /// Fires when [otherAccountsHere] gains a device.
  Stream<void> get otherAccountsChanges => _otherAccountsChanges.stream;

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
        versionMismatch: _mismatches[device.id],
        reachedOverVpn: _isOverVpn(device, _ready[device.id]),
        isHeard: _heardRecently(device.id),
      ),
  ];

  bool _heardRecently(String deviceId) => switch (_heardPaired[deviceId]) {
    final heard? => DateTime.now().difference(heard) < _nearbyLifetime,
    null => false,
  };

  /// Turns "Also reach it over my VPN" on or off for the paired
  /// [deviceId]. On, it is dialed at its VPN addresses when the local
  /// network doesn't find it, and it is asked for them. Off, they are
  /// forgotten, and a session running over the VPN ends.
  Future<void> setReachOverVpn(String deviceId, {required bool reach}) async {
    final trusted = trustStore[deviceId];
    if (trusted == null || trusted.reachOverVpn == reach) {
      return;
    }

    final session = _ready[deviceId];
    final wasOverVpn = _isOverVpn(trusted, session);
    await trustStore.save(switch (reach) {
      true => trusted.copyWith(reachOverVpn: true),
      false => trusted.copyWith(reachOverVpn: false, vpnAddresses: const []),
    });
    await _tellVpnReach(deviceId);

    if (!reach) {
      _vpnReacher.stop(deviceId);
      if (wasOverVpn) {
        await session?.close();
      }

      return;
    }

    if (_running && !_sessions.containsKey(deviceId)) {
      _vpnReacher.reach(deviceId);
    }
  }

  /// Sets the address [deviceId] is also tried at over the VPN, such as
  /// "100.101.102.103" or a MagicDNS name, or clears it when [address] is
  /// null or blank. Kept on this device only.
  Future<void> setReachAt(String deviceId, String? address) async {
    final trusted = trustStore[deviceId];
    if (trusted == null) {
      return;
    }

    await trustStore.save(trusted.withReachAt(address));
    if (trusted.reachOverVpn && _running && !_sessions.containsKey(deviceId)) {
      _vpnReacher.reach(deviceId);
    }
  }

  /// When this engine last started, or null while it never ran.
  DateTime? get startedAt => _startedAt;

  /// When discovery last heard another Ferret device, paired or not. A
  /// network that keeps devices apart, such as café or hotel Wi-Fi, never
  /// lets one through.
  DateTime? get lastHeardOthers => _lastHeardOthers;

  /// The local networks found when the network last changed.
  List<LocalNetwork> get localNetworks => _knownNetworks.current;

  Stream<List<DeviceStatus>> get deviceChanges => _deviceChanges.stream;

  /// Requests to pair by comparing codes, for the UI to confirm.
  Stream<PairingPrompt> get pairingPrompts => _pairingPrompts.stream;

  /// Devices that joined through another of the user's devices.
  Stream<DeviceJoined> get joins => _joins.stream;

  /// Devices another of the user's devices wants to add or remove here,
  /// waiting for the user's answer, oldest first.
  List<GroupRequest> get groupRequests => [..._groupRequests.values];

  Stream<List<GroupRequest>> get groupRequestChanges =>
      _groupRequestChanges.stream;

  /// Whether pairings are shared between the user's devices.
  bool get sharesPairings => settings.get<bool>(sharePairingsKey) ?? true;

  /// Turns sharing pairings on or off. Turning it on tells the connected
  /// devices about each other right away; turning it off lets go of what
  /// waits for an answer.
  Future<void> setSharesPairings(bool shares) async {
    await settings.set(sharePairingsKey, shares);
    if (shares) {
      await _introduceEveryone();
      return;
    }

    _dropGroupRequests((_) => true);
  }

  /// Whether this device announces itself on every network, instead of
  /// only where it met a paired device.
  bool get alwaysVisible => settings.get<bool>(alwaysVisibleKey) ?? false;

  Future<void> setAlwaysVisible(bool visible) async {
    await settings.set(alwaysVisibleKey, visible);
    await _updateVisibility();
  }

  /// Whether this device announces itself on the network right now: while
  /// someone pairs a device ([stayVisible]), before anything is paired, on
  /// a network where it met a paired device, or everywhere with
  /// [alwaysVisible]. Elsewhere it only listens, so paired devices that
  /// announce still find it, and it them.
  bool get isAnnouncing =>
      alwaysVisible ||
      _visibleHolds > 0 ||
      trustStore.devices.isEmpty ||
      _knownNetworks.isLearning ||
      _onKnownNetwork;

  /// Announces this device until the hold is released, for screens where
  /// the person is pairing one: the other device has to see this one.
  VisibleHold stayVisible() {
    _visibleHolds++;
    unawaited(_updateVisibility());
    return VisibleHold(() {
      _visibleHolds--;
      unawaited(_updateVisibility());
    });
  }

  Future<void> _refreshNetworks() async {
    await _knownNetworks.refresh();
    _onKnownNetwork = await _knownNetworks.isOnKnown();
  }

  Future<void> _updateVisibility() async {
    if (_discovery case final QuietDiscovery quiet) {
      final announcing = isAnnouncing;
      if (quiet.isAnnouncing == announcing) {
        return;
      }

      printLog(switch (announcing) {
        true => 'Announcing this device on the network',
        false => 'Listening only: no paired device met on this network',
      });
      try {
        await quiet.setAnnouncing(announcing);
      } on Object catch (error) {
        printWarning('Discovery did not change', error);
      }
    }
  }

  /// Announces slow down while every paired device is connected: nobody
  /// paired is left to find, and others are still answered at once. A
  /// drop brings the usual pace back with an announce.
  Future<void> _updatePace() async {
    if (!_running) {
      return;
    }

    final devices = trustStore.devices;
    multicastNeed.setMissing(
      devices.any((device) => !_ready.containsKey(device.id)),
    );
    if (_discovery case final PacedDiscovery paced) {
      final relaxed =
          devices.isNotEmpty &&
          devices.every((device) => _ready.containsKey(device.id));
      if (paced.isRelaxed == relaxed) {
        return;
      }

      try {
        await paced.setRelaxed(relaxed);
      } on Object catch (error) {
        printWarning('Discovery did not change pace', error);
      }
    }
  }

  /// Discovery that keeps the network passing multicast just by running,
  /// such as Bonjour on Android, rests while nothing needs to hear it.
  Future<void> _updateListening() async {
    if (!_running) {
      return;
    }

    if (_discovery case final ListeningDiscovery listening) {
      final needed = multicastNeed.isNeeded;
      if (listening.isListening == needed) {
        return;
      }

      printLog(switch (needed) {
        true => 'Listening for devices: ${multicastNeed.reasons.join(', ')}',
        false => 'Not listening: no paired device missing, no one looking',
      });
      try {
        await listening.setListening(needed);
      } on Object catch (error) {
        printWarning('Discovery did not change listening', error);
      }
    }
  }

  /// A paired device was reached at [host]: its network is one to announce
  /// on from now on. Not this device's own address, where its ferret-cli
  /// calls from.
  Future<void> _rememberNetwork(String host) async {
    try {
      final own = _ownAddresses ??= await _ownAddressSource();
      if (own.contains(host) || !await _knownNetworks.rememberHost(host)) {
        return;
      }

      _onKnownNetwork = await _knownNetworks.isOnKnown();
      await _updateVisibility();
    } on Object catch (error) {
      printDebug('Could not remember this network: $error');
    }
  }

  /// Answers [request]. Yes adds or removes the device here, and the
  /// device added gets no more than the one that asked may use. No to an
  /// addition keeps the device out until it is paired here by hand; no to
  /// a removal keeps it, and the same removal isn't asked about again.
  Future<void> answerGroupRequest(
    GroupRequest request, {
    required bool yes,
  }) async {
    if (!identical(_groupRequests[request.device.id], request)) {
      return;
    }

    _dropGroupRequests((each) => identical(each, request));
    final introducer = trustStore[request.introducer.id];
    switch ((request, yes)) {
      case (JoinRequest(), true) when introducer != null:
        final joined = DeviceJoined(
          device: request.device,
          introducer: introducer,
        );
        if (await _admit(joined)) {
          _nearbyChanges.add(nearby);
          _emitDevices();
          await _introduceEveryone();
        }
      case (JoinRequest(), _):
        await trustStore.forget(
          .new(
            id: request.device.id,
            at: _afterPairing(request.device),
            by: .here,
          ),
        );
      case (final RemovalRequest removal, true):
        await _removeIntroduced((
          device: removal.device,
          at: removal.forgottenAt,
        ));
      case (final RemovalRequest removal, false):
        await settings.set(keptRemovalsKey, {
          ..._keptRemovals(),
          removal.device.id: removal.forgottenAt.millisecondsSinceEpoch,
        });
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
    _boundPort = server.port;
    _subscriptions
      ..add(server.listen(_onIncomingSocket))
      ..add(_discovery.peers.listen(_onPeer))
      ..add(_departures.listen(_onDeparture))
      ..add(trustStore.changes.listen((_) => _emitDevices()))
      ..add(trustStore.changes.listen((_) => unawaited(_forgetOldAccess())))
      ..add(trustStore.changes.listen((_) => unawaited(_tellPaired())))
      ..add(access.changes.listen((id) => unawaited(_applyAccess(id))))
      ..add(trustStore.changes.listen((_) => unawaited(_updateVisibility())))
      ..add(trustStore.changes.listen((_) => unawaited(_updatePace())))
      ..add(multicastNeed.changes.listen((_) => unawaited(_updateListening())));

    if (!_featuresStarted) {
      _featuresStarted = true;
      for (final feature in _features.values) {
        await feature.start(ScopedFeatureHost(this, access, feature.id));
      }
    }

    await _forgetOldAccess();
    await _tellPaired();
    await _knownNetworks.startLearningAfterUpdate(
      hasDevices: trustStore.devices.isNotEmpty,
    );
    await _refreshNetworks();
    await _updateVisibility();
    multicastNeed.setRunning(true);
    await _updatePace();
    await _updateListening();
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

      if (trusted.reachOverVpn) {
        _vpnReacher.reach(trusted.id);
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
    multicastNeed.setRunning(false);
    _droppedRecently.clear();
    _vpnReacher.stopAll();
    // Whoever asked asks again on the next connection.
    _dropGroupRequests((_) => true);
    await _discovery.stop();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _server?.close();
    _server = null;
    _boundPort = null;

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

  /// Announces again, such as after the network changed, or only listens
  /// on a network where no paired device was met.
  Future<void> refresh() async {
    _ownAddresses = null;
    await _refreshNetworks();
    await _updateVisibility();
    await _discovery.announceNow();
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
      final blocked = access.isBlocked(session.remoteDeviceId, featureId);
      if (!session.supports(featureId) || blocked) {
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
      protocolVersion: device.newestProtocol,
      oldestProtocolVersion: device.oldestProtocol,
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

    final mismatch = VersionMismatch.between(
      device.toInfo(identity.deviceId),
      DeviceInfo(
        protocolVersion: offer.protocolVersion,
        oldestProtocolVersion: offer.oldestProtocolVersion,
      ),
    );
    if (mismatch != null) {
      return PairingFailed(switch (mismatch.update) {
        .thisDevice => PairingFailure.updateThisDevice,
        .otherDevice => PairingFailure.updateOtherDevice,
      }, offer.name);
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
    _mismatches.remove(deviceId);
    _dropGroupRequests(
      (request) =>
          request.device.id == deviceId || request.introducer.id == deviceId,
    );
    await session?.close(.GOODBYE_REASON_UNPAIRED);
    _emitDevices();
    if (everywhere) {
      await _introduceEveryone();
    }
  }

  /// Lets [newId] take the place of [oldId], such as a phone that was reset
  /// or replaced and paired again with a new identity: it keeps the old
  /// one's nickname here and what it may use, and the old one is forgotten
  /// on every device of the user's.
  Future<void> replace(String oldId, {required String newId}) async {
    final old = trustStore[oldId];
    final replacement = trustStore[newId];
    if (old == null || replacement == null || oldId == newId) {
      return;
    }

    if ((old.nickname, replacement.nickname) case (final nickname?, null)) {
      await trustStore.rename(newId, nickname);
    }

    final blocked = access.blockedFor(oldId);
    if (blocked.isNotEmpty) {
      await access.blockAll(newId, blocked);
    }

    await unpair(oldId, everywhere: true);
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
  /// their next connection. With [remember] false the name is not kept as
  /// the person's choice, such as one Ferret picked to tell accounts apart.
  Future<void> rename(String name, {bool remember = true}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _device.name) {
      return;
    }

    _device = _device.renamed(trimmed);
    if (remember) {
      await settings.set('device.name', trimmed);
    }

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

    await _refreshNetworks();
    await _updateVisibility();
    await _restartDiscovery();

    final dials = <Future<void>>[];
    for (final trusted in trustStore.devices) {
      if (_sessions[trusted.id] case final session? when !session.isClosed) {
        continue;
      }

      if (_mismatches.containsKey(trusted.id)) {
        continue;
      }

      if ((trusted.lastHost, trusted.lastPort) case (
        final host?,
        final port?,
      )) {
        dials.add(_dial(host, port, expectedDeviceId: trusted.id));
      }

      if (trusted.reachOverVpn) {
        _vpnReacher.reach(trusted.id);
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

  /// Another account on this computer running Ferret holds the preferred
  /// port, so the next few are tried before any free one: a known range
  /// the firewall rules can open ahead of time.
  Future<ServerSocket> _bind() async {
    for (final candidate in candidatePorts(preferredPort)) {
      try {
        return await ServerSocket.bind(InternetAddress.anyIPv4, candidate);
      } on SocketException {
        printDebug('Port $candidate is taken');
      }
    }

    printWarning('Ports from $preferredPort on are taken; using a free one');
    return ServerSocket.bind(InternetAddress.anyIPv4, 0);
  }

  Announce _announce() => Announce(
    protocolVersion: protocolVersion,
    deviceId: identity.deviceId,
    name: device.name,
    platform: device.platform,
    formFactor: device.formFactor,
    port: port,
  );

  Future<Hello> _hello(String remoteId) async {
    final trusted = trustStore[remoteId];
    final sharesVpn = trusted?.sharesVpn ?? false;

    return Hello(
      device: localDevice,
      features: [
        for (final feature in _features.values)
          if (feature.isAvailable && !access.isBlocked(remoteId, feature.id))
            feature.support,
      ],
      listenPort: port,
      wantsVpnAddresses: trusted?.reachOverVpn ?? false,
      vpnAddresses: [if (sharesVpn) ...await _vpnAddressSource()],
    );
  }

  /// Tells [deviceId] whether this device wants its VPN addresses, and
  /// this device's own when it asked for them.
  Future<void> _tellVpnReach(String deviceId) async {
    final session = _ready[deviceId];
    final trusted = trustStore[deviceId];
    if (session == null || trusted == null) {
      return;
    }

    final reach = VpnReach(
      wantsAddresses: trusted.reachOverVpn,
      includesAddresses: trusted.sharesVpn,
      addresses: [if (trusted.sharesVpn) ...await _vpnAddressSource()],
    );
    await session.send(sessionFeature, reach).catchError((Object _) {});
  }

  Future<void> _onVpnReach(Session session, VpnReach reach) async {
    final trusted = trustStore[session.remoteDeviceId];
    if (trusted == null) {
      return;
    }

    final askedNow = reach.wantsAddresses && !trusted.sharesVpn;
    final learned = switch (trusted.reachOverVpn && reach.includesAddresses) {
      true => _vpnFilter.accept(reach.addresses),
      false => null,
    };
    await trustStore.save(
      trusted.copyWith(sharesVpn: reach.wantsAddresses, vpnAddresses: learned),
    );

    if (askedNow) {
      await _tellVpnReach(session.remoteDeviceId);
    }
  }

  /// One try at reaching [deviceId] when the local network didn't find
  /// it: its last local address first, then the address typed for it,
  /// then its VPN addresses. Says whether there is nothing left to try.
  Future<bool> _reachOverVpn(String deviceId) async {
    final trusted = trustStore[deviceId];
    if (!_running || trusted == null || !trusted.reachOverVpn) {
      return true;
    }

    if (_ready.containsKey(deviceId) || _mismatches.containsKey(deviceId)) {
      return true;
    }

    if (_sessions.containsKey(deviceId)) {
      return false;
    }

    for (final (host, port) in _dialOrder(trusted)) {
      await _dial(host, port, expectedDeviceId: deviceId);
      if (_ready.containsKey(deviceId)) {
        printLog('Reached $deviceId over the VPN or its last address');
        return true;
      }
    }

    return false;
  }

  List<(String, int)> _dialOrder(TrustedDevice trusted) {
    final port = trusted.lastPort ?? defaultPort;
    final order = <(String, int)>[
      if (trusted.lastHost case final host?) (host, port),
      if (trusted.reachAt case final typed?)
        VpnAddresses.parseTyped(typed, port),
      for (final address in trusted.vpnAddresses) (address, port),
    ];

    final seen = <(String, int)>{};
    return [
      for (final target in order)
        if (seen.add(target)) target,
    ];
  }

  /// The hosts a session with [device] counts as over the VPN for.
  List<String> _vpnHostsOf(TrustedDevice device) => [
    ...device.vpnAddresses,
    if (device.reachAt case final typed?)
      VpnAddresses.parseTyped(typed, defaultPort).$1,
  ];

  /// Bytes sent and received with [deviceId] since this connection over
  /// the user's VPN was made, or null while it isn't reached that way.
  /// Away from the Wi-Fi, this is what a data plan counts.
  int? vpnBytesOf(String deviceId) {
    final (device, session) = (trustStore[deviceId], _ready[deviceId]);
    if (device == null || session == null || !_isOverVpn(device, session)) {
      return null;
    }

    return session.channel.bytesSent + session.channel.bytesReceived;
  }

  bool _isOverVpn(TrustedDevice device, Session? session) {
    final host = session?.remoteHost;
    if (host == null) {
      return false;
    }

    return VpnAddresses.isVpnHost(host, _vpnHostsOf(device));
  }

  /// Whether a new connection this device opens to [deviceId] would win
  /// over its current session, so dialing it isn't wasted.
  bool _wouldReplace(Session session) =>
      session.initiatorDeviceId == identity.deviceId ||
      identity.deviceId.compareTo(session.initiatorDeviceId) < 0;

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

  /// With [expected], a device that answers with another key never learns
  /// this device's own: a forged announce of a paired device can't find out
  /// who heard it.
  Future<SecureChannel> _openChannel(
    String host,
    int port, {
    String? expected,
  }) async {
    final connection = await SocketConnection.connect(host, port);
    return SecureChannel.initiate(
      connection,
      identity.keyPair,
      acceptRemote: switch (expected) {
        final id? => (key) => _isTrustedKey(id, key),
        null => null,
      },
    );
  }

  void _onPeer(DiscoveredPeer peer) {
    unawaited(_onPeerFrom(peer));
  }

  Set<String>? _ownAddresses;

  /// This device's own addresses, loopback included.
  Future<Set<String>> _systemOwnAddresses() async => {
    '127.0.0.1',
    ...await _localAddresses(),
  };

  Future<void> _onPeerFrom(DiscoveredPeer peer) async {
    // A virtual machine behind this computer's NAT (an Android emulator)
    // announces through this computer's own address. Dialing that reaches
    // this device itself, never the announcer.
    if (peer.port == port && peer.deviceId != identity.deviceId) {
      final own = _ownAddresses ??= await _ownAddressSource();
      if (own.contains(peer.host)) {
        return;
      }
    }

    if (peer.deviceId != identity.deviceId) {
      _lastHeardOthers = DateTime.now();
      await _noteOtherAccount(peer);
    }

    if (trustStore.isTrusted(peer.deviceId)) {
      final wasHeard = _heardRecently(peer.deviceId);
      _heardPaired[peer.deviceId] = DateTime.now();
      if (!wasHeard && _ready[peer.deviceId] == null) {
        _emitDevices();
      }

      if (_stillMismatched(peer)) {
        return;
      }

      if (!_sessions.containsKey(peer.deviceId) ||
          _movesOffVpn(peer.deviceId, peer.host)) {
        unawaited(_dial(peer.host, peer.port, expectedDeviceId: peer.deviceId));
      }

      return;
    }

    _nearby[peer.deviceId] = (peer: peer, seen: DateTime.now());
    _dropStaleNearby();
    _nearbyChanges.add(nearby);
  }

  /// A device reached over the VPN showed up on the local network: the
  /// session moves there, where it is faster.
  bool _movesOffVpn(String deviceId, String host) {
    final session = _ready[deviceId];
    final trusted = trustStore[deviceId];
    if (session == null || trusted == null) {
      return false;
    }

    final hosts = _vpnHostsOf(trusted);
    return _isOverVpn(trusted, session) &&
        !VpnAddresses.isVpnHost(host, hosts) &&
        _wouldReplace(session);
  }

  Future<void> _noteOtherAccount(DiscoveredPeer peer) async {
    final deviceId = peer.deviceId;
    final isSameKind = peer.announce.platform == device.platform;
    if (!isSameKind ||
        _otherAccounts.contains(deviceId) ||
        _ownAccount.contains(deviceId)) {
      return;
    }

    final own = _ownAddresses ??= await _ownAddressSource();
    if (!own.contains(peer.host) || !_ownAccount.add(deviceId)) {
      return;
    }

    if (await _sameAccount.runs(peer)) {
      return;
    }

    _ownAccount.remove(deviceId);
    _otherAccounts.add(deviceId);
    _otherAccountsChanges.add(null);
  }

  /// A device that needs an update is dialed again only once it announces
  /// another protocol version, so it isn't asked again and again for nothing.
  bool _stillMismatched(DiscoveredPeer peer) {
    final mismatch = _mismatches[peer.deviceId];
    if (mismatch == null) {
      return false;
    }

    final announced = peer.announce.protocolVersion;
    if (announced == 0 || announced == mismatch.remoteProtocol) {
      return true;
    }

    _mismatches.remove(peer.deviceId);
    _emitDevices();
    return false;
  }

  void _onDeparture(String deviceId) {
    if (_heardPaired.remove(deviceId) != null) {
      _emitDevices();
    }

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
      final channel = await _openChannel(
        host,
        port,
        expected: expectedDeviceId,
      );
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

    channel.messageLimit = _strangerMessageLimit;
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

    if (_strangers >= _maxStrangers) {
      await channel.close();
      return;
    }

    _strangers++;
    try {
      await _answerPairing(channel, remoteId, connection.remoteHost);
    } finally {
      _strangers--;
    }
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

  /// Whether [deviceId], unknown here, may be one a paired device is about
  /// to introduce: this device takes introductions, has devices that could
  /// make them, and never forgot this one.
  bool _mayJoinSoon(String deviceId) =>
      sharesPairings &&
      trustStore.devices.isNotEmpty &&
      trustStore.forgottenOf(deviceId) == null;

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
      if (_mayJoinSoon(remoteId)) {
        // One of this device's own devices may have just vouched for it
        // there, and its word hasn't arrived here yet. Saying "not paired"
        // would make it forget this device for good; once the word arrives
        // this side dials it instead.
        printDebug('Device $remoteId is not known here yet');
        await exchange.close();
        return;
      }

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
        true => _answerComparison(exchange, envelope, request, host),
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
  ///
  /// A device turned down, or left without an answer, waits before it may
  /// ask again: until then its requests are turned down without a prompt.
  Future<bool> _answerComparison(
    PairingExchange exchange,
    Envelope envelope,
    PairingRequest request,
    String host,
  ) async {
    final deviceId = request.device.id;
    if (request.commitment.isEmpty ||
        _pairingCooldown.holds(host: host, deviceId: deviceId)) {
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
    if (answer == .rejected || answer == .expired) {
      _pairingCooldown.strike(host: host, deviceId: deviceId);
    }

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
    channel.messageLimit = SecureChannel.maxMessageLength;
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
      remoteHost: host,
      isBlocked: (feature) => access.isBlocked(remoteId, feature),
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
      await session.sendHello(await _hello(remoteId));
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
      // A VPN address is kept apart from the local one, so the local
      // network is still tried first next time.
      final overVpn = _isOverVpn(trusted, session);
      final learned = hello.vpnAddresses.isNotEmpty && trusted.reachOverVpn;
      await trustStore.save(
        trusted.copyWith(
          name: hello.device.name,
          platform: hello.device.platform,
          formFactor: hello.device.formFactor,
          lastSeen: DateTime.now(),
          lastHost: switch (overVpn) {
            true => null,
            false => host,
          },
          lastPort: hello.listenPort,
          sharesVpn: hello.wantsVpnAddresses,
          vpnAddresses: switch (learned) {
            true => _vpnFilter.accept(hello.vpnAddresses),
            false => null,
          },
        ),
      );
      if (!overVpn) {
        unawaited(_rememberNetwork(host));
      }
    }

    if (VersionMismatch.between(localDevice, hello.device)
        case final mismatch?) {
      printWarning(
        '${session.remoteDeviceId} speaks protocol '
        '${mismatch.remoteProtocol}; ${mismatch.update.name} needs an update',
      );
      _mismatches[session.remoteDeviceId] = mismatch;
      _droppedRecently.remove(session.remoteDeviceId);
      await session.close();
      _emitDevices();
      return;
    }

    if (_mismatches.remove(session.remoteDeviceId) != null) {
      _emitDevices();
    }

    _ready[session.remoteDeviceId] = session;
    unawaited(_updatePace());
    _vpnReacher.stop(session.remoteDeviceId);
    _droppedRecently.remove(session.remoteDeviceId);
    _watchWeak(session);
    printLog('Connected to ${hello.device.name}');
    final opened = [
      for (final feature in _features.values)
        if (!access.isBlocked(session.remoteDeviceId, feature.id)) feature,
    ];
    _openedFeatures[session] = opened;
    for (final feature in opened) {
      feature.onSessionOpened(session);
    }

    _emitSessions();
    await _introduceEveryone();

    final askedForVpn =
        hello.wantsVpnAddresses && !(trusted?.sharesVpn ?? false);
    if (askedForVpn) {
      await _tellVpnReach(session.remoteDeviceId);
    }
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

  /// A device may vouch for others, never for more than it may use itself:
  /// otherwise turning a feature off for it could be undone by a second
  /// key it introduces.
  Future<void> _inheritAccess(String deviceId, TrustedDevice introducer) =>
      access.blockAll(deviceId, access.blockedFor(introducer.id));

  /// Takes in what a paired device says about the user's other devices.
  /// Additions from a device just paired by hand here come in right away;
  /// every other addition, and every removal, waits for the user here.
  Future<void> _onIntroduce(Session session, Envelope envelope) async {
    final introduce = payloadOf(envelope, Introduce.new);
    final introducer = trustStore[session.remoteDeviceId];
    if (introduce == null || introducer == null || !sharesPairings) {
      return;
    }

    final proposal = await _roster.review(introduce, introducer);
    final now = DateTime.now();
    final kept = _keptRemovals();
    final asked = <GroupRequest>[
      for (final removal in proposal.removals)
        if (!_groupRequests.containsKey(removal.device.id) &&
            kept[removal.device.id] != removal.at.millisecondsSinceEpoch)
          RemovalRequest(
            device: removal.device,
            introducer: introducer,
            askedAt: now,
            expiresAt: now.add(_groupRequestLifetime),
            forgottenAt: removal.at,
          ),
    ];

    var joined = false;
    final withoutAsking =
        introducer.introducedBy == null &&
        now.difference(introducer.pairedAt) < _justPaired;
    for (final join in proposal.joins) {
      if (withoutAsking) {
        joined = await _admit(join) || joined;
        continue;
      }

      if (!_groupRequests.containsKey(join.device.id)) {
        asked.add(
          JoinRequest(
            device: join.device,
            introducer: introducer,
            askedAt: now,
            expiresAt: now.add(_groupRequestLifetime),
          ),
        );
      }
    }

    for (final request in asked) {
      printLog(
        '${request.introducer.name} asks about ${request.device.name}',
      );
      _groupRequests[request.device.id] = request;
      _groupRequestTimers[request.device.id] = Timer(
        request.expiresAt.difference(now),
        () => unawaited(answerGroupRequest(request, yes: false)),
      );
    }

    // What was forgotten meanwhile, or paired by hand, needs no answer.
    final settled = _dropGroupRequests(
      (request) => switch (request) {
        JoinRequest(:final device) =>
          trustStore.isTrusted(device.id) ||
              switch (trustStore.forgottenOf(device.id)) {
                final forgotten? => !device.pairedAt.isAfter(forgotten.at),
                null => false,
              },
        RemovalRequest(:final device) => !trustStore.isTrusted(device.id),
      },
      announce: false,
    );
    if (asked.isNotEmpty || settled) {
      _groupRequestChanges.add(groupRequests);
    }

    if (!joined) {
      return;
    }

    _nearbyChanges.add(nearby);
    _emitDevices();
    await _introduceEveryone();
  }

  /// Trusts a device another one vouched for, and dials it.
  Future<bool> _admit(DeviceJoined joined) async {
    if (!await _roster.join(joined)) {
      return false;
    }

    printLog('${joined.device.name} joined through ${joined.introducer.name}');
    _nearby.remove(joined.device.id);
    _joins.add(joined);
    if ((joined.device.lastHost, joined.device.lastPort) case (
      final host?,
      final port?,
    )) {
      unawaited(_dial(host, port, expectedDeviceId: joined.device.id));
    }

    return true;
  }

  Future<void> _removeIntroduced(RosterRemoval removal) async {
    if (!await _roster.remove(removal)) {
      return;
    }

    await _sessions[removal.device.id]?.close(.GOODBYE_REASON_UNPAIRED);
    _nearbyChanges.add(nearby);
    _emitDevices();
    await _introduceEveryone();
  }

  Map<String, int> _keptRemovals() =>
      switch (settings.get<Object?>(keptRemovalsKey)) {
        final Map<String, Object?> stored => {
          for (final MapEntry(:key, :value) in stored.entries)
            if (value case final int at) key: at,
        },
        _ => const {},
      };

  /// Returns whether any request was dropped.
  bool _dropGroupRequests(
    bool Function(GroupRequest request) test, {
    bool announce = true,
  }) {
    final dropped = [
      for (final request in _groupRequests.values)
        if (test(request)) request,
    ];
    for (final request in dropped) {
      _groupRequests.remove(request.device.id);
      _groupRequestTimers.remove(request.device.id)?.cancel();
    }

    if (dropped.isNotEmpty && announce) {
      _groupRequestChanges.add(groupRequests);
    }

    return dropped.isNotEmpty;
  }

  Future<void> _route(Session session, Envelope envelope) async {
    if (envelope.feature == sessionFeature) {
      if (payloadOf(envelope, VpnReach.new) case final reach?) {
        await _onVpnReach(session, reach);
      }

      return;
    }

    if (envelope.feature == pairingFeature) {
      await _onIntroduce(session, envelope);
      return;
    }

    final feature = _features[envelope.feature];
    final blocked = access.isBlocked(session.remoteDeviceId, envelope.feature);
    if (feature == null || !feature.isAvailable || blocked) {
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
      unawaited(_updatePace());
      // Only an announce after the drop says Ferret is still open there.
      _heardPaired.remove(session.remoteDeviceId);
      unawaited(_weakWatches.remove(session.remoteDeviceId)?.cancel());
      unawaited(_presenceWatches.remove(session.remoteDeviceId)?.cancel());
      if (_running && session.remoteGoodbye == null) {
        _droppedRecently.add(session.remoteDeviceId);
      }

      for (final feature in _openedFeatures.remove(session) ?? const []) {
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
    if (trustStore[session.remoteDeviceId]?.reachOverVpn ?? false) {
      _vpnReacher.reach(session.remoteDeviceId);
    }
  }

  /// Starts the session with [deviceId] again, so both sides learn what it
  /// may use now: features it lost stop at once, on both ends.
  Future<void> _applyAccess(String deviceId) async {
    final session = _sessions[deviceId];
    if (session == null) {
      return;
    }

    // A session still saying hello sent the old list, so it goes too.
    await session.close();
    if (_running) {
      unawaited(_reconnect(deviceId));
    }
  }

  Future<void> _forgetOldAccess() async {
    final deviceIds = switch (settings.get<Object?>(DeviceAccess.blockedKey)) {
      final Map<String, Object?> stored => [...stored.keys],
      _ => const <String>[],
    };

    for (final deviceId in deviceIds) {
      if (trustStore[deviceId] == null) {
        await access.forget(deviceId);
      }
    }
  }

  /// Lets each feature drop what it keeps for devices no longer paired.
  Future<void> _tellPaired() async {
    final paired = {for (final device in trustStore.devices) device.id};
    for (final feature in _features.values) {
      try {
        await feature.onPairedDevices(paired);
      } on Object catch (error, stackTrace) {
        printError(
          '${feature.id} could not let go of removed devices',
          error,
          stackTrace,
        );
      }
    }
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
    _dropGroupRequests(
      (request) =>
          request.device.id == deviceId || request.introducer.id == deviceId,
    );
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

  /// A device's line changes with its link (weak or steady) and with
  /// whether someone is at it.
  void _watchWeak(Session session) {
    final deviceId = session.remoteDeviceId;
    unawaited(_weakWatches.remove(deviceId)?.cancel());
    unawaited(_presenceWatches.remove(deviceId)?.cancel());
    _weakWatches[deviceId] = session.weakChanges.listen(
      (_) => _emitDevices(),
    );
    _presenceWatches[deviceId] = session.presenceChanges.listen(
      (_) => _emitDevices(),
    );
  }

  void _emitSessions() {
    _sessionChanges.add(sessions);
    _emitDevices();
  }

  void _emitDevices() => _deviceChanges.add(devices);
}
