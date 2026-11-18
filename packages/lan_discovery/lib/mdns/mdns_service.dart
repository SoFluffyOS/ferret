/// One service instance to announce on mDNS.
class MdnsService {
  const MdnsService({
    required this.type,
    required this.instance,
    required this.host,
    required this.port,
    this.txt = const {},
  });

  /// The service type, such as `_ipp._tcp`.
  final String type;

  /// The instance name, one DNS label.
  final String instance;

  /// The host name to publish addresses under, one DNS label, without
  /// `.local`.
  final String host;
  final int port;
  final Map<String, String> txt;

  List<String> get typeName => [...type.split('.'), 'local'];

  List<String> get instanceName => [instance, ...typeName];

  List<String> get hostName => [host, 'local'];
}
