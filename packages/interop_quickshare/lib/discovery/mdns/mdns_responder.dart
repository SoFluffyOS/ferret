import 'dart:io';

import 'package:interop_quickshare/discovery/mdns/dns_message.dart';
import 'package:interop_quickshare/discovery/mdns/dns_question.dart';
import 'package:interop_quickshare/discovery/mdns/dns_record.dart';
import 'package:interop_quickshare/discovery/mdns/dns_type.dart';
import 'package:interop_quickshare/discovery/mdns/dns_wire.dart';
import 'package:interop_quickshare/discovery/mdns/mdns_service.dart';

/// Builds the mDNS and DNS-SD answers for one service (RFC 6762, 6763).
/// It only decides what to say; [MdnsAdvertiser] does the talking.
class MdnsResponder {
  const MdnsResponder(this.service);

  /// How long others may remember the records that name this host.
  static const hostTtl = 120;

  /// How long others may remember that the service exists.
  static const serviceTtl = 4500;
  static const _serviceList = ['_services', '_dns-sd', '_udp', 'local'];

  final MdnsService service;

  /// Everything about the service, to tell the network unasked that it
  /// is there at [address], or with [goodbye] that it is gone.
  DnsMessage announcement(InternetAddress address, {bool goodbye = false}) {
    final records = [_ptr, _srv, _txt, _a(address)];
    return DnsMessage(
      isResponse: true,
      answers: switch (goodbye) {
        true => [for (final record in records) record.withTtl(0)],
        false => records,
      },
    );
  }

  /// The answer to [query] for a device that reaches this one at
  /// [address], or null when it asks nothing about this service.
  DnsMessage? answer(DnsMessage query, InternetAddress address) {
    if (query.isResponse) {
      return null;
    }

    final answers = <DnsRecord>[];
    final additionals = <DnsRecord>[];
    for (final question in query.questions) {
      _answerQuestion(question, address, answers, additionals);
    }

    if (answers.isEmpty) {
      return null;
    }

    final unique = _withoutRepeats(answers);
    return DnsMessage(
      isResponse: true,
      answers: unique,
      additionals: _withoutRepeats(additionals, known: unique),
    );
  }

  /// [records] with each name and type once, and none that [known]
  /// already holds.
  List<DnsRecord> _withoutRepeats(
    List<DnsRecord> records, {
    List<DnsRecord> known = const [],
  }) {
    final seen = {for (final record in known) _keyOf(record)};
    return [
      for (final record in records)
        if (seen.add(_keyOf(record))) record,
    ];
  }

  String _keyOf(DnsRecord record) =>
      '${record.type} ${record.name.join('.').toLowerCase()}';

  void _answerQuestion(
    DnsQuestion question,
    InternetAddress address,
    List<DnsRecord> answers,
    List<DnsRecord> additionals,
  ) {
    final (ptr, srv, txt, a) = (_ptr, _srv, _txt, _a(address));
    bool asksFor(int type) =>
        question.type == type || question.type == DnsType.any;

    if (DnsWire.sameName(question.name, _serviceList) && asksFor(DnsType.ptr)) {
      answers.add(
        DnsRecord.ptr(_serviceList, service.typeName, serviceTtl),
      );
      return;
    }

    if (DnsWire.sameName(question.name, service.typeName) &&
        asksFor(DnsType.ptr)) {
      answers.add(ptr);
      additionals.addAll([srv, txt, a]);
      return;
    }

    if (DnsWire.sameName(question.name, service.instanceName)) {
      if (asksFor(DnsType.srv)) {
        answers.add(srv);
        additionals.add(a);
      }

      if (asksFor(DnsType.txt)) {
        answers.add(txt);
      }

      return;
    }

    if (DnsWire.sameName(question.name, service.hostName) &&
        asksFor(DnsType.a)) {
      answers.add(a);
    }
  }

  DnsRecord get _ptr =>
      DnsRecord.ptr(service.typeName, service.instanceName, serviceTtl);

  DnsRecord get _srv => DnsRecord.srv(
    service.instanceName,
    service.hostName,
    service.port,
    hostTtl,
  );

  DnsRecord get _txt =>
      DnsRecord.txt(service.instanceName, service.txt, serviceTtl);

  DnsRecord _a(InternetAddress address) =>
      DnsRecord.a(service.hostName, address, hostTtl);
}
