import 'dart:io';

import 'package:ferret_mirror_airplay/src/discovery/airplay_service_info.dart';
import 'package:lan_discovery/lan_discovery.dart';

/// Makes this receiver show up under Screen Mirroring on iPhones, iPads
/// and Macs on the same network, by announcing the two AirPlay services
/// (`_airplay._tcp` and `_raop._tcp`) over mDNS.
class AirPlayAdvertiser {
  final List<MdnsAdvertiser> _running = [];

  bool get isRunning => _running.isNotEmpty;

  /// Announces [info] with connections accepted on [port]. Throws a
  /// [SocketException] when mDNS can't be used.
  Future<void> start(AirPlayServiceInfo info, int port) async {
    await stop();
    try {
      for (final service in servicesFor(info, port)) {
        final advertiser = MdnsAdvertiser(service);
        await advertiser.start();
        _running.add(advertiser);
      }
    } on Object {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    final running = [..._running];
    _running.clear();
    for (final advertiser in running) {
      await advertiser.stop();
    }
  }

  static List<MdnsService> servicesFor(AirPlayServiceInfo info, int port) => [
    MdnsService(
      type: AirPlayServiceInfo.airplayType,
      instance: info.airplayInstance,
      host: info.hostName,
      port: port,
      txt: info.airplayTxt,
    ),
    MdnsService(
      type: AirPlayServiceInfo.raopType,
      instance: info.raopInstance,
      host: info.hostName,
      port: port,
      txt: info.raopTxt,
    ),
  ];
}
