import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:interop_quickshare/discovery/mdns/dns_type.dart';
import 'package:interop_quickshare/discovery/mdns/dns_wire.dart';

/// One resource record in a DNS message.
class DnsRecord {
  const DnsRecord({
    required this.name,
    required this.type,
    required this.ttl,
    required this.data,
    this.isUnique = false,
  });

  /// Points from a service type to one instance of it.
  factory DnsRecord.ptr(List<String> name, List<String> target, int ttl) =>
      DnsRecord(
        name: name,
        type: DnsType.ptr,
        ttl: ttl,
        data: DnsWire.encodeName(target),
      );

  /// Says on which [host] and [port] an instance listens.
  factory DnsRecord.srv(
    List<String> name,
    List<String> host,
    int port,
    int ttl,
  ) => DnsRecord(
    name: name,
    type: DnsType.srv,
    ttl: ttl,
    isUnique: true,
    data: Uint8List.fromList([
      0, 0, // priority
      0, 0, // weight
      port >> 8, port & 0xff,
      ...DnsWire.encodeName(host),
    ]),
  );

  /// The `key=value` attributes of an instance.
  factory DnsRecord.txt(
    List<String> name,
    Map<String, String> entries,
    int ttl,
  ) {
    final data = BytesBuilder();
    for (final MapEntry(:key, :value) in entries.entries) {
      final entry = utf8.encode('$key=$value');
      if (entry.length > DnsWire.maxTxtEntry) {
        throw ArgumentError.value(key, 'entries', 'TXT entry too long');
      }

      data
        ..addByte(entry.length)
        ..add(entry);
    }

    if (data.isEmpty) {
      data.addByte(0);
    }

    return DnsRecord(
      name: name,
      type: DnsType.txt,
      ttl: ttl,
      isUnique: true,
      data: data.takeBytes(),
    );
  }

  /// The IPv4 [address] of a host.
  factory DnsRecord.a(List<String> name, InternetAddress address, int ttl) =>
      DnsRecord(
        name: name,
        type: DnsType.a,
        ttl: ttl,
        isUnique: true,
        data: address.rawAddress,
      );

  final List<String> name;
  final int type;

  /// Seconds the record may be cached. Zero takes it back.
  final int ttl;

  /// The record's content, in wire form.
  final Uint8List data;

  /// Whether this device is the only one that can own the record. Others
  /// then replace what they cached instead of adding to it.
  final bool isUnique;

  DnsRecord withTtl(int ttl) => DnsRecord(
    name: name,
    type: type,
    ttl: ttl,
    data: data,
    isUnique: isUnique,
  );
}
