import 'dart:async';
import 'dart:convert';

import 'package:lan_discovery/lan_discovery.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/discovery/discovered_peer.dart';

/// Finds devices with DNS-SD over multicast DNS: each one offers
/// `_ferret._tcp.local` and answers when asked who does.
///
/// The TXT record says what an `Announce` says. Its `id` is the device id,
/// which is a fingerprint of the device's public key, so whoever answers at
/// that address has to hold that key or the connection is dropped. Like an
/// announce, it carries no secrets.
class MdnsDiscovery implements ActiveDiscovery {
  MdnsDiscovery({
    this.rescanEvery = const Duration(seconds: 30),
    this.collectFor = const Duration(seconds: 2),
    Future<MdnsLink> Function()? open,
  }) : _open = open ?? _bind;

  static const serviceType = '_ferret._tcp';
  static const _maxNameBytes = 200;

  /// How often to ask again while nobody calls [scan].
  final Duration rescanEvery;

  /// How long one scan waits for answers.
  final Duration collectFor;

  final Future<MdnsLink> Function() _open;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  MdnsLink? _link;
  MdnsAdvertiser? _advertiser;
  MdnsBrowser? _browser;
  Announce? _self;

  static Future<MdnsLink> _bind() => MdnsSocket.bind(orAnyPort: true);

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => _departures.stream;

  @override
  bool get isBlocked => _link?.isBlocked ?? false;

  /// Starts offering [self] and looking for others. Called again with new
  /// details, such as another name, it takes the old offer back first.
  @override
  Future<void> start(Announce self) async {
    if (_link != null) {
      if (_sameOffer(_self, self)) {
        return announceNow();
      }

      await stop();
    }

    _self = self;
    final link = await _open();
    _link = link;

    final browser = MdnsBrowser(
      serviceType,
      rescanEvery: rescanEvery,
      collectFor: collectFor,
      ignore: self.deviceId,
      socket: link,
    );
    _browser = browser;
    _subscriptions
      ..add(browser.appeared.listen(_onInstance))
      ..add(browser.scans.listen((_) => _onScanned(browser)))
      ..add(browser.left.listen(_departures.add));
    await browser.start();

    // Without the mDNS port nobody's questions arrive, so there is nothing
    // to answer. Looking still works.
    if (!link.sharesPort) {
      return;
    }

    final advertiser = MdnsAdvertiser(
      serviceFor(self),
      reannounceEvery: null,
      socket: link,
    );
    _advertiser = advertiser;
    await advertiser.start();
  }

  @override
  Future<void> announceNow() async => _advertiser?.announce();

  @override
  Future<void> scan() async => _browser?.scan();

  /// Says goodbye, so others drop this device right away.
  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _advertiser?.stop();
    await _browser?.stop();
    _link?.close();
    _advertiser = null;
    _browser = null;
    _link = null;
  }

  /// Devices that are still there say nothing new, so they are repeated
  /// after each scan for whoever forgets the quiet ones.
  void _onScanned(MdnsBrowser browser) {
    for (final instance in browser.instances) {
      _onInstance(instance);
    }
  }

  void _onInstance(MdnsInstance instance) {
    final announce = announceFrom(instance);
    if (announce == null || announce.deviceId == _self?.deviceId) {
      return;
    }

    _peers.add(
      DiscoveredPeer(announce: announce, host: instance.address.address),
    );
  }

  bool _sameOffer(Announce? first, Announce second) =>
      first != null &&
      first.deviceId == second.deviceId &&
      first.name == second.name &&
      first.port == second.port &&
      first.platform == second.platform &&
      first.formFactor == second.formFactor;

  /// The DNS-SD service that stands for [self]. The instance and host names
  /// are the device id, so they are unique without probing and say nothing
  /// about the computer's real host name.
  static MdnsService serviceFor(Announce self) => MdnsService(
    type: serviceType,
    instance: self.deviceId,
    host: 'ferret-${self.deviceId}',
    port: self.port,
    txt: txtFor(self),
  );

  /// The TXT entries that say what [self]'s announce says, and nothing
  /// more. The system's Bonjour offers the same ones.
  static Map<String, String> txtFor(Announce self) => {
    'id': self.deviceId,
    'v': '${self.protocolVersion}',
    'p': '${self.platform.value}',
    'f': '${self.formFactor.value}',
    'n': _fit(self.name),
  };

  /// What [instance] says about its device, or null when it isn't a Ferret
  /// device or contradicts itself.
  static Announce? announceFrom(MdnsInstance instance) => announceFromRecord(
    name: instance.name,
    txt: instance.txt,
    port: instance.port,
  );

  /// What a DNS-SD record with this instance [name], [txt] and [port] says
  /// about its device, or null when it isn't a Ferret device or contradicts
  /// itself: its id has to be its instance name.
  static Announce? announceFromRecord({
    required String name,
    required Map<String, String> txt,
    required int port,
  }) {
    final deviceId = txt['id'];
    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceId.toLowerCase() != name.toLowerCase() ||
        port <= 0) {
      return null;
    }

    return Announce(
      protocolVersion: int.tryParse(txt['v'] ?? ''),
      deviceId: deviceId,
      name: txt['n'] ?? '',
      platform: Platform.valueOf(int.tryParse(txt['p'] ?? '') ?? 0),
      formFactor: FormFactor.valueOf(int.tryParse(txt['f'] ?? '') ?? 0),
      port: port,
    );
  }

  /// A TXT entry holds 255 bytes; a long name is cut at a character.
  static String _fit(String name) {
    var fitted = name;
    while (utf8.encode(fitted).length > _maxNameBytes) {
      fitted = fitted.substring(0, fitted.length - 1);
    }

    return fitted;
  }
}
