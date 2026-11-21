import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_bonjour/src/bonjour_backend.dart';
import 'package:ferret_bonjour/src/bonsoir_backend.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Finds and offers Ferret devices with the system's own Bonjour.
///
/// It offers the same `_ferret._tcp` service with the same TXT entries as
/// [MdnsDiscovery], so devices on either find each other. The difference is
/// who sends the packets: the system, which an iPhone allows without
/// Apple's multicast entitlement and which macOS and Android keep working
/// across sleep and network changes. Like an announce, it carries no
/// secrets: whoever answers has to hold the device id's key.
class BonjourDiscovery implements ActiveDiscovery {
  BonjourDiscovery({
    BonjourBackend backend = const BonsoirBackend(),
    this.repeatEvery = const Duration(seconds: 30),
    this.collectFor = const Duration(seconds: 1),
  }) : _backend = backend;

  final BonjourBackend _backend;

  /// How often devices still offered are passed on again. The system says
  /// nothing while they stay, and quiet devices are forgotten.
  final Duration repeatEvery;

  /// How long a scan waits for answers.
  final Duration collectFor;

  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Devices seen, by instance name.
  final Map<String, DiscoveredPeer> _seen = {};
  BonjourOffer? _offer;
  BonjourBrowser? _browser;
  Timer? _repeat;
  Announce? _self;
  bool _denied = false;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => _departures.stream;

  /// Whether the system refused, or may have: an Apple browser that isn't
  /// allowed on the local network just waits and says nothing, so finding
  /// nobody counts too. [CombinedDiscovery] calls it blocked only when the
  /// multicast announce, which can tell, is blocked as well.
  @override
  bool get isBlocked => _denied || _seen.isEmpty;

  @override
  Future<void> start(Announce self) async {
    if (_browser != null) {
      if (_sameOffer(_self, self)) {
        return;
      }

      await stop();
    }

    _self = self;
    _denied = false;
    final browser = await _backend.browse(MdnsDiscovery.serviceType);
    _browser = browser;
    _subscriptions.add(browser.events.listen(_onEvent));
    _repeat = .periodic(repeatEvery, (_) => _repeatSeen());

    try {
      final offer = await _backend.offer(
        name: self.deviceId,
        type: MdnsDiscovery.serviceType,
        port: self.port,
        txt: MdnsDiscovery.txtFor(self),
      );
      _offer = offer;
      _subscriptions.add(offer.failures.listen(_onFailed));
    } on Object catch (error) {
      // Looking still works without being seen.
      printDebug('Bonjour could not offer this device: $error');
    }
  }

  /// The system repeats the offer by itself.
  @override
  Future<void> announceNow() async {}

  /// The system keeps browsing; what it already found is passed on again
  /// and anything new has a moment to arrive.
  @override
  Future<void> scan() async {
    _repeatSeen();
    await Future<void>.delayed(collectFor);
  }

  @override
  Future<void> stop() async {
    _repeat?.cancel();
    _repeat = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    final (offer, browser) = (_offer, _browser);
    _offer = null;
    _browser = null;
    _seen.clear();
    await _quietly(offer?.stop);
    await _quietly(browser?.stop);
  }

  void _onEvent(BonjourEvent event) {
    switch (event) {
      case BonjourFound(:final service):
        _onFound(service);
      case BonjourLost(:final name):
        if (_seen.remove(name) case final peer?) {
          _departures.add(peer.deviceId);
        }
      case final BonjourFailed failed:
        _onFailed(failed);
    }
  }

  void _onFound(BonjourService service) {
    final peer = peerFrom(service);
    if (peer == null || peer.deviceId == _self?.deviceId) {
      return;
    }

    _denied = false;
    _seen[service.name] = peer;
    _peers.add(peer);
  }

  void _onFailed(BonjourFailed failed) {
    if (failed.denied) {
      _denied = true;
    }

    printDebug('Bonjour stopped: ${failed.detail}');
  }

  void _repeatSeen() {
    for (final peer in _seen.values) {
      _peers.add(peer);
    }
  }

  bool _sameOffer(Announce? first, Announce second) =>
      first != null &&
      first.deviceId == second.deviceId &&
      first.name == second.name &&
      first.port == second.port &&
      first.platform == second.platform &&
      first.formFactor == second.formFactor;

  Future<void> _quietly(Future<void> Function()? action) async {
    if (action == null) {
      return;
    }

    try {
      await action();
    } on Object catch (error) {
      printDebug('Bonjour: $error');
    }
  }

  /// The device [service] stands for, reached at its first IPv4 address
  /// that isn't link-local (Ferret listens on IPv4), or null when it isn't a Ferret device, has
  /// no such address, or contradicts itself.
  static DiscoveredPeer? peerFrom(BonjourService service) {
    final announce = MdnsDiscovery.announceFromRecord(
      name: service.name,
      txt: service.txt,
      port: service.port,
    );
    if (announce == null) {
      return null;
    }

    for (final address in service.addresses) {
      final parsed = InternetAddress.tryParse(address);
      if (parsed != null && parsed.type == .IPv4 && !parsed.isLinkLocal) {
        return DiscoveredPeer(announce: announce, host: parsed.address);
      }
    }

    return null;
  }
}
