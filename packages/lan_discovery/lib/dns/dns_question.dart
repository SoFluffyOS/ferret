/// One question in a DNS message.
class DnsQuestion {
  const DnsQuestion({
    required this.name,
    required this.type,
    this.wantsUnicast = false,
  });

  /// The labels of the name asked about, such as `_ipp`, `_tcp`, `local`.
  final List<String> name;
  final int type;

  /// Asks for the answer to be sent straight back instead of to everyone.
  final bool wantsUnicast;
}
