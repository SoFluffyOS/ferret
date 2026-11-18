import 'dart:io';

import 'package:interop_quickshare/crypto/crypto.dart';
import 'package:interop_quickshare/discovery/mdns/mdns.dart';
import 'package:interop_quickshare/discovery/quickshare_endpoint_info.dart';
import 'package:interop_quickshare/discovery/quickshare_service.dart';

/// Makes this device show up in the Quick Share sheet of phones on the
/// same network, by announcing the Quick Share service over mDNS.
///
/// Nothing is sent until [start], and [stop] takes the announcement
/// back. Each start uses a new endpoint id and host name.
class QuickShareAdvertiser {
  QuickShareAdvertiser({required this.info});

  /// The name and kind phones will show for this device.
  final QuickShareEndpointInfo Function() info;

  MdnsAdvertiser? _mdns;
  String? _endpointId;

  bool get isRunning => _mdns?.isRunning ?? false;

  /// The id phones know this device by while it is visible.
  String? get endpointId => _endpointId;

  /// Announces that Quick Share connections are accepted on [port].
  /// Throws a [SocketException] when mDNS can't be used.
  Future<void> start(int port) async {
    await stop();
    final endpointId = QuickShareService.newEndpointId();
    final mdns = MdnsAdvertiser(serviceFor(endpointId, port, info()));
    await mdns.start();
    _mdns = mdns;
    _endpointId = endpointId;
  }

  Future<void> stop() async {
    final mdns = _mdns;
    _mdns = null;
    _endpointId = null;
    await mdns?.stop();
  }

  /// The mDNS service that stands for the endpoint [endpointId]. The
  /// host name is random, so the computer's real name never goes out.
  static MdnsService serviceFor(
    String endpointId,
    int port,
    QuickShareEndpointInfo info,
  ) => MdnsService(
    type: QuickShareService.type,
    instance: QuickShareService.instanceName(endpointId),
    host: 'qs-${_hex(SecureBytes.random(6))}',
    port: port,
    txt: {'n': info.toTxt()},
  );

  static String _hex(List<int> bytes) => [
    for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
  ].join();
}
