import 'dart:io';

/// One service instance another device announced over mDNS.
class MdnsInstance {
  const MdnsInstance({
    required this.name,
    required this.address,
    required this.port,
    required this.txt,
  });

  /// The instance label, the part before the service type.
  final String name;

  /// Where the answer came from, which is where the device can be reached
  /// from this network.
  final InternetAddress address;
  final int port;
  final Map<String, String> txt;
}
