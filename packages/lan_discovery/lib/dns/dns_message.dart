import 'dart:typed_data';

import 'package:lan_discovery/dns/dns_question.dart';
import 'package:lan_discovery/dns/dns_record.dart';
import 'package:lan_discovery/dns/dns_type.dart';
import 'package:lan_discovery/dns/dns_wire.dart';

/// A DNS message, as far as mDNS service discovery needs it.
class DnsMessage {
  const DnsMessage({
    this.id = 0,
    this.isResponse = false,
    this.questions = const [],
    this.answers = const [],
    this.additionals = const [],
  });

  static const _headerLength = 12;
  static const _responseFlags = 0x8400;
  static const _responseBit = 0x8000;
  static const _maxEntries = 64;
  static const _srvFixedLength = 6;

  final int id;
  final bool isResponse;
  final List<DnsQuestion> questions;
  final List<DnsRecord> answers;
  final List<DnsRecord> additionals;

  /// Reads a packet. Returns null when it isn't a well-formed message.
  static DnsMessage? decode(Uint8List packet) {
    if (packet.length < _headerLength) {
      return null;
    }

    final header = ByteData.sublistView(packet);
    final counts = [
      for (var index = 4; index < 12; index += 2) header.getUint16(index),
    ];
    if (counts.any((count) => count > _maxEntries)) {
      return null;
    }

    var offset = _headerLength;
    final questions = <DnsQuestion>[];
    for (var index = 0; index < counts[0]; index++) {
      final name = DnsWire.readName(packet, offset);
      if (name == null || name.$2 + 4 > packet.length) {
        return null;
      }

      questions.add(
        DnsQuestion(
          name: name.$1,
          type: header.getUint16(name.$2),
          wantsUnicast: header.getUint16(name.$2 + 2) & DnsType.topBit != 0,
        ),
      );
      offset = name.$2 + 4;
    }

    final sections = <List<DnsRecord>>[];
    for (final count in counts.skip(1)) {
      final records = <DnsRecord>[];
      for (var index = 0; index < count; index++) {
        final name = DnsWire.readName(packet, offset);
        if (name == null || name.$2 + 10 > packet.length) {
          return null;
        }

        final fixed = name.$2;
        final length = header.getUint16(fixed + 8);
        final dataStart = fixed + 10;
        if (dataStart + length > packet.length) {
          return null;
        }

        final type = header.getUint16(fixed);
        final (target, port) = _pointsAt(packet, type, dataStart, length);
        records.add(
          DnsRecord(
            name: name.$1,
            type: type,
            isUnique: header.getUint16(fixed + 2) & DnsType.topBit != 0,
            ttl: header.getUint32(fixed + 4),
            data: Uint8List.sublistView(packet, dataStart, dataStart + length),
            target: target,
            port: port,
          ),
        );
        offset = dataStart + length;
      }

      sections.add(records);
    }

    return DnsMessage(
      id: header.getUint16(0),
      isResponse: header.getUint16(2) & _responseBit != 0,
      questions: questions,
      answers: sections[0],
      additionals: sections[2],
    );
  }

  /// The name and port a PTR or SRV record at [dataStart] carries. Names in
  /// there may point back into [packet], so they are read here.
  static (List<String>?, int) _pointsAt(
    Uint8List packet,
    int type,
    int dataStart,
    int length,
  ) {
    if (type == DnsType.ptr) {
      return (DnsWire.readName(packet, dataStart)?.$1, 0);
    }

    if (type != DnsType.srv || length < _srvFixedLength) {
      return (null, 0);
    }

    final port = ByteData.sublistView(packet).getUint16(dataStart + 4);
    final host = DnsWire.readName(packet, dataStart + _srvFixedLength)?.$1;
    return (host, port);
  }

  /// The wire form.
  Uint8List encode() {
    final bytes = BytesBuilder()
      ..add(_uint16(id))
      ..add(
        _uint16(switch (isResponse) {
          true => _responseFlags,
          false => 0,
        }),
      )
      ..add(_uint16(questions.length))
      ..add(_uint16(answers.length))
      ..add(_uint16(0))
      ..add(_uint16(additionals.length));
    for (final question in questions) {
      bytes
        ..add(DnsWire.encodeName(question.name))
        ..add(_uint16(question.type))
        ..add(
          _uint16(switch (question.wantsUnicast) {
            true => DnsType.classInternet | DnsType.topBit,
            false => DnsType.classInternet,
          }),
        );
    }

    for (final record in [...answers, ...additionals]) {
      final recordClass = switch (record.isUnique) {
        true => DnsType.classInternet | DnsType.topBit,
        false => DnsType.classInternet,
      };
      bytes
        ..add(DnsWire.encodeName(record.name))
        ..add(_uint16(record.type))
        ..add(_uint16(recordClass))
        ..add(_uint16(record.ttl >> 16))
        ..add(_uint16(record.ttl & 0xffff))
        ..add(_uint16(record.data.length))
        ..add(record.data);
    }

    return bytes.takeBytes();
  }

  static List<int> _uint16(int value) => [(value >> 8) & 0xff, value & 0xff];
}
