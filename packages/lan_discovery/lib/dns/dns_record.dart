import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lan_discovery/dns/dns_type.dart';
import 'package:lan_discovery/dns/dns_wire.dart';

/// One resource record in a DNS message.
class DnsRecord {
  const DnsRecord({
    required this.name,
    required this.type,
    required this.ttl,
    required this.data,
    this.isUnique = false,
    this.target,
    this.port = 0,
  });

  /// Points from a service type to one instance of it.
  factory DnsRecord.ptr(List<String> name, List<String> target, int ttl) =>
      DnsRecord(
        name: name,
        type: DnsType.ptr,
        ttl: ttl,
        data: DnsWire.encodeName(target),
        target: target,
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
    target: host,
    port: port,
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

  /// The name a PTR or SRV record points at: the instance for a PTR, the
  /// host for an SRV. Read while decoding, because names inside [data] may
  /// be compressed against the whole packet.
  final List<String>? target;

  /// The port of an SRV record, 0 for other types.
  final int port;

  /// The `key=value` attributes of a TXT record. Entries without `=` are
  /// flags and come back with an empty value. Empty for other types and
  /// for a cut-off record.
  Map<String, String> get txtEntries {
    if (type != DnsType.txt) {
      return const {};
    }

    final entries = <String, String>{};
    var offset = 0;
    while (offset < data.length) {
      final length = data[offset];
      final end = offset + 1 + length;
      if (end > data.length) {
        return const {};
      }

      final entry = utf8.decode(
        Uint8List.sublistView(data, offset + 1, end),
        allowMalformed: true,
      );
      offset = end;
      if (entry.isEmpty) {
        continue;
      }

      final separator = entry.indexOf('=');
      if (separator < 0) {
        entries[entry] = '';
        continue;
      }

      entries[entry.substring(0, separator)] = entry.substring(separator + 1);
    }

    return entries;
  }

  /// The IPv4 address of an A record, or null for other types.
  InternetAddress? get address {
    if (type != DnsType.a || data.length != 4) {
      return null;
    }

    return InternetAddress.fromRawAddress(data);
  }

  DnsRecord withTtl(int ttl) => DnsRecord(
    name: name,
    type: type,
    ttl: ttl,
    data: data,
    isUnique: isUnique,
    target: target,
    port: port,
  );
}
