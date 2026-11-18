/// One question in a DNS message.
class DnsQuestion {
  const DnsQuestion({required this.name, required this.type});

  /// The labels of the name asked about, such as `_ipp`, `_tcp`, `local`.
  final List<String> name;
  final int type;
}
