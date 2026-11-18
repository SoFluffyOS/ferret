import 'dart:io';

import 'package:interop_localsend/models/localsend_constants.dart';
import 'package:interop_localsend/models/localsend_info.dart';

/// A LocalSend member found on the network, and where to reach it.
class LocalSendPeer {
  const LocalSendPeer({
    required this.info,
    required this.address,
    required this.lastSeen,
  });

  final LocalSendInfo info;
  final InternetAddress address;
  final DateTime lastSeen;

  String get fingerprint => info.fingerprint;

  int get port => info.port ?? LocalSendDefaults.port;

  bool get isEncrypted => info.isEncrypted;

  /// The address of one API route on this member.
  Uri route(String name, [Map<String, String> query = const {}]) => Uri(
    scheme: switch (isEncrypted) {
      true => LocalSendDefaults.https,
      false => LocalSendDefaults.http,
    },
    host: address.address,
    port: port,
    path: '${LocalSendDefaults.apiPath}/$name',
    queryParameters: switch (query.isEmpty) {
      true => null,
      false => query,
    },
  );
}
