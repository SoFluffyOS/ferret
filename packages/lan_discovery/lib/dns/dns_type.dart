/// The DNS record types and flags mDNS service discovery needs.
abstract final class DnsType {
  static const a = 1;
  static const ptr = 12;
  static const txt = 16;
  static const srv = 33;
  static const any = 255;

  static const classInternet = 1;

  /// In a question: answer by unicast. In a record: replace what you had.
  static const topBit = 0x8000;
}
