import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:ferret_mirror_airplay/src/crypto/crypto.dart';
import 'package:ferret_mirror_airplay/src/discovery/discovery.dart';
import 'package:ferret_mirror_airplay/src/fairplay/fairplay.dart';
import 'package:ferret_mirror_airplay/src/receiver/airplay_connection.dart';
import 'package:ferret_mirror_airplay/src/receiver/airplay_feed.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:lan_discovery/lan_discovery.dart';

/// Shows an iPhone's or iPad's screen on this computer: the phone picks
/// this receiver under Control Center, Screen Mirroring, and its picture
/// arrives as a [MirrorFeed]. Nothing is installed on the phone.
///
/// It speaks legacy AirPlay screen mirroring, video only. Nothing listens
/// and nothing is announced until [start]; every phone has to pass
/// [allow] before a single picture is taken.
class AirPlayReceiver implements MirrorReceiver {
  AirPlayReceiver({
    required this.identity,
    this.allow,
    this.port = 0,
    this.display = const AirPlayDisplay(),
    this.askTimeout = const Duration(seconds: 30),
    this.advertise = true,
    FairPlayDecrypt decrypt = playfairDecrypt,
  }) : _decrypt = decrypt;

  static const routeId = AirPlayConnection.routeId;
  static const _maxConnections = 8;

  /// Whether listening should be on before the user says anything. A Mac
  /// already has its own AirPlay receiver, so there it starts off.
  static bool get onByDefault => !Platform.isMacOS;

  /// Who this receiver is to phones, asked for at each [start]. A function,
  /// so the receiver can be created before the app has loaded its keys.
  final Future<AirPlayIdentity> Function() identity;

  /// Decides about each phone, given the name it claims: show a prompt,
  /// or check a PIN. Nothing is accepted without a `true` from here, or
  /// from the one given to [start], which comes first. With neither, every
  /// phone is turned away.
  final ReceiverAllow? allow;

  /// The TCP port to listen on, 0 for any free one. macOS keeps 7000 for
  /// its own receiver, so a fixed port must be another.
  final int port;
  final AirPlayDisplay display;

  /// How long [allow] may take before the phone is turned away.
  final Duration askTimeout;

  /// Announce the receiver over mDNS. Off in tests that connect directly.
  final bool advertise;

  final FairPlayDecrypt _decrypt;
  final StreamController<MirrorFeed> _incoming = .broadcast();
  final AirPlayAdvertiser _advertiser = AirPlayAdvertiser();
  final Set<AirPlayConnection> _connections = {};
  ServerSocket? _server;
  ReceiverAllow? _allowNow;

  @override
  String get id => routeId;

  @override
  bool get listensByDefault => onByDefault;

  @override
  bool get isListening => _server != null;

  @override
  Stream<MirrorFeed> get incoming => _incoming.stream;

  /// The port phones connect to while listening.
  int? get boundPort => _server?.port;

  /// Ready on desktops where the FairPlay library came with the app.
  @override
  Future<RouteStatus> status() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return const RouteUnsupported();
    }

    try {
      _decrypt(Uint8List(164), Uint8List(72));
    } on Object {
      return const RouteUnsupported();
    }

    return const RouteReady();
  }

  /// Starts listening and announces this receiver as [name]. Throws a
  /// [SocketException] when the port or mDNS can't be used.
  @override
  Future<void> start(String name, {ReceiverAllow? allow}) async {
    await stop();
    _allowNow = allow ?? this.allow;
    final loaded = await identity();
    final info = AirPlayServiceInfo(
      name: name,
      identity: loaded,
      publicKey: await PairVerify.publicKeyOf(loaded.signingSeed),
      display: display,
    );
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    server.listen(
      (socket) => _onSocket(socket, info),
      onError: (Object _) {},
    );
    _server = server;
    if (!advertise) {
      return;
    }

    try {
      await _advertiser.start(info, server.port);
    } on Object {
      await stop();
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    await _advertiser.stop();
    await server?.close();
    for (final connection in [..._connections]) {
      await connection.close(.stoppedHere);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _incoming.close();
  }

  void _onSocket(Socket socket, AirPlayServiceInfo info) {
    final welcome =
        LocalNetworks.contains(socket.remoteAddress) &&
        _connections.length < _maxConnections;
    if (!welcome) {
      socket.destroy();
      return;
    }

    final connection = AirPlayConnection(
      socket: socket,
      info: info,
      allow: _ask,
      askTimeout: askTimeout,
      decrypt: _decrypt,
      onFeed: _onFeed,
      onClosed: _connections.remove,
    );
    _connections.add(connection);
    connection.start();
  }

  Future<bool> _ask(String deviceName) async {
    final allow = _allowNow;
    if (allow == null) {
      return false;
    }

    return allow(deviceName);
  }

  void _onFeed(AirPlayFeed feed) {
    if (_incoming.isClosed) {
      return;
    }

    printLog('AirPlay: a device started mirroring');
    _incoming.add(feed);
  }
}
