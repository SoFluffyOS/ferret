import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:handoff/services/browser/browser_channel.dart';
import 'package:handoff/services/browser/browser_origin.dart';

/// The WebSocket server the browser extension talks to. It listens on
/// 127.0.0.1 only, and turns away every request that doesn't come from an
/// extension origin before upgrading it.
class BrowserBridgeServer {
  BrowserBridgeServer({
    List<int>? ports,
    this.maxConnections = 16,
    this.pingInterval = const Duration(seconds: 30),
  }) : ports = ports ?? defaultPorts;

  static const firstPort = 47650;
  static const _closeTimeout = Duration(seconds: 2);

  /// The extension tries the same range, in the same order.
  static const portCount = 5;
  static final defaultPorts = [
    for (var offset = 0; offset < portCount; offset++) firstPort + offset,
  ];

  final List<int> ports;
  final int maxConnections;
  final Duration pingInterval;

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _requests;
  final Set<WebSocket> _sockets = {};

  /// The port it listens on, once started.
  int? get port => _server?.port;

  int get connectionCount => _sockets.length;

  /// Listens on the first free port of [ports] and hands each accepted
  /// connection to [onChannel]. Null when every port is taken.
  Future<int?> start(void Function(BrowserChannel channel) onChannel) async {
    if (_server case final server?) {
      return server.port;
    }

    for (final candidate in ports) {
      try {
        final server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          candidate,
        );
        server
          ..autoCompress = false
          ..serverHeader = null
          ..idleTimeout = const Duration(seconds: 10);
        _server = server;
        _requests = server.listen(
          (request) => unawaited(_handle(request, onChannel)),
        );
        return server.port;
      } on SocketException catch (error) {
        printDebug(
          'Browser bridge port $candidate is taken (${error.osError?.errorCode})',
        );
      }
    }

    return null;
  }

  Future<void> stop() async {
    await _requests?.cancel();
    _requests = null;

    for (final socket in _sockets.toList()) {
      await socket
          .close(BrowserCloseCode.goingAway)
          .timeout(_closeTimeout, onTimeout: () => null);
    }

    _sockets.clear();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(
    HttpRequest request,
    void Function(BrowserChannel channel) onChannel,
  ) async {
    final origin = _single(request.headers['origin']);
    final host = _single(request.headers['host']);
    final remote = request.connectionInfo?.remoteAddress;

    if (remote == null || !remote.isLoopback) {
      return _reject(request, HttpStatus.forbidden);
    }

    if (origin == null ||
        !BrowserOrigin.isExtension(origin) ||
        !BrowserOrigin.isLoopbackHost(host)) {
      return _reject(request, HttpStatus.forbidden);
    }

    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      return _reject(request, HttpStatus.upgradeRequired);
    }

    if (_sockets.length >= maxConnections) {
      return _reject(request, HttpStatus.serviceUnavailable);
    }

    final WebSocket socket;
    try {
      socket = await WebSocketTransformer.upgrade(
        request,
        compression: CompressionOptions.compressionOff,
      );
    } on Object catch (error) {
      printDebug('Browser bridge upgrade failed (${error.runtimeType})');
      return;
    }

    socket.pingInterval = pingInterval;
    _sockets.add(socket);
    unawaited(socket.done.whenComplete(() => _sockets.remove(socket)));
    onChannel(_WebSocketChannel(socket, origin));
  }

  /// Several values for one header is a trick, never a browser.
  static String? _single(List<String>? values) {
    if (values == null || values.length != 1) {
      return null;
    }

    return values.single;
  }

  static Future<void> _reject(HttpRequest request, int status) async {
    try {
      request.response.statusCode = status;
      await request.response.close();
    } on Object catch (error) {
      printDebug('Browser bridge reject failed (${error.runtimeType})');
    }
  }
}

class _WebSocketChannel implements BrowserChannel {
  _WebSocketChannel(this._socket, this.origin) {
    _subscription = _socket.listen(
      _onData,
      onDone: () => unawaited(_messages.close()),
      onError: (Object _) => unawaited(_messages.close()),
      cancelOnError: true,
    );
  }

  final WebSocket _socket;
  final StreamController<String> _messages = .new();
  late final StreamSubscription<Object?> _subscription;

  @override
  final String origin;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void send(Map<String, Object?> message) {
    if (_socket.readyState != WebSocket.open) {
      return;
    }

    try {
      _socket.add(jsonEncode(message));
    } on Object catch (error) {
      printDebug('Browser bridge send failed (${error.runtimeType})');
    }
  }

  @override
  Future<void> close([
    int code = BrowserCloseCode.goingAway,
    String reason = '',
  ]) async {
    await _subscription.cancel();
    await _messages.close();
    await _socket
        .close(code, reason)
        .timeout(BrowserBridgeServer._closeTimeout, onTimeout: () => null);
  }

  void _onData(Object? data) {
    if (data is String) {
      _messages.add(data);
      return;
    }

    unawaited(close(BrowserCloseCode.protocolError, 'text only'));
  }
}
