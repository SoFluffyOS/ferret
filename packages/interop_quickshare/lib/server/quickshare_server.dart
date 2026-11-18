import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:interop_quickshare/connection/connection.dart';
import 'package:interop_quickshare/crypto/crypto.dart';
import 'package:interop_quickshare/server/inbound_session.dart';
import 'package:interop_quickshare/server/quickshare_receive_delegate.dart';
import 'package:lan_discovery/lan_discovery.dart';

/// The receiving side of Quick Share: a TCP server that senders connect
/// to after finding this device on mDNS.
///
/// Nothing listens until [start]. It only serves addresses on the local
/// network, and every offer goes through the [delegate], which must ask
/// a person.
class QuickShareServer {
  QuickShareServer({
    required this.delegate,
    this.port = 0,
    this.maxSessions = 4,
    this.timeouts = const QuickShareTimeouts(),
    InternetAddress? address,
  }) : _address = address ?? InternetAddress.anyIPv4;

  final QuickShareReceiveDelegate delegate;

  /// The port to listen on. Quick Share has no fixed one, so the default
  /// takes any free port; mDNS tells senders which.
  final int port;

  /// How many senders may be connected at once. More are turned away.
  final int maxSessions;
  final QuickShareTimeouts timeouts;

  final InternetAddress _address;
  final Map<String, InboundSession> _sessions = {};
  ServerSocket? _server;

  bool get isRunning => _server != null;

  /// The port the server listens on, or null when it is stopped.
  int? get boundPort => _server?.port;

  /// Whether an offer is waiting or files are arriving.
  bool get isBusy => _sessions.values.any((session) => session.isBusy);

  /// Starts listening and returns the port. Throws a [SocketException]
  /// when the port can't be bound.
  Future<int> start() async {
    if (_server case final running?) {
      return running.port;
    }

    final server = await ServerSocket.bind(_address, port);
    server.listen(
      _onConnection,
      onError: (Object error) =>
          printDebug('Quick Share server: ${error.runtimeType}'),
    );
    _server = server;
    return server.port;
  }

  /// Stops listening. Sessions in progress end as cancelled by this
  /// device.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close();
    for (final session in [..._sessions.values]) {
      await session.cancel();
    }
  }

  /// Cancels [sessionId] from this device.
  Future<void> cancelSession(String sessionId) async {
    await _sessions[sessionId]?.cancel();
  }

  void _onConnection(Socket socket) {
    final allowed =
        LocalNetworks.contains(socket.remoteAddress) &&
        _sessions.length < maxSessions;
    if (!allowed) {
      socket.destroy();
      return;
    }

    final session = InboundSession(
      id: _hex(SecureBytes.random(8)),
      socket: socket,
      delegate: delegate,
      timeouts: timeouts,
    );
    _sessions[session.id] = session;
    unawaited(
      session.run().whenComplete(() => _sessions.remove(session.id)),
    );
  }

  static String _hex(List<int> bytes) => [
    for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
  ].join();
}
