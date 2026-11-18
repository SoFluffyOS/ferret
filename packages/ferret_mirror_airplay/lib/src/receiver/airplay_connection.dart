import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:ferret_mirror_airplay/src/crypto/crypto.dart';
import 'package:ferret_mirror_airplay/src/discovery/discovery.dart';
import 'package:ferret_mirror_airplay/src/fairplay/fairplay.dart';
import 'package:ferret_mirror_airplay/src/plist/plist.dart';
import 'package:ferret_mirror_airplay/src/receiver/airplay_feed.dart';
import 'package:ferret_mirror_airplay/src/receiver/timing_client.dart';
import 'package:ferret_mirror_airplay/src/rtsp/rtsp.dart';
import 'package:ferret_mirror_airplay/src/stream/stream.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// One phone's control connection, from its first `/info` to `TEARDOWN`:
/// pairing, FairPlay, the session setup, and the video stream it opens.
class AirPlayConnection {
  AirPlayConnection({
    required Socket socket,
    required this.info,
    required this.allow,
    required this.onFeed,
    required this.onClosed,
    this.askTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(seconds: 30),
    FairPlayDecrypt decrypt = playfairDecrypt,
  }) : _socket = socket,
       _remote = socket.remoteAddress,
       _fairPlay = FairPlaySession(decrypt: decrypt),
       _pairVerify = PairVerify(signingSeed: info.identity.signingSeed);

  static const routeId = 'airplay';
  static const _mirrorStream = 110;
  static const _audioStream = 96;
  static const _maxNameLength = 64;
  static const _teardownGrace = Duration(seconds: 1);

  final AirPlayServiceInfo info;

  /// Asked once per session with the phone's name, before anything is
  /// shown. The name is what the phone claims, nothing more.
  final Future<bool> Function(String deviceName) allow;
  final void Function(AirPlayFeed feed) onFeed;
  final void Function(AirPlayConnection connection) onClosed;
  final Duration askTimeout;

  /// With a feed running, this long without a byte from the phone means
  /// it is gone.
  final Duration idleTimeout;

  final Socket _socket;
  final InternetAddress _remote;
  final FairPlaySession _fairPlay;
  final PairVerify _pairVerify;
  final RtspRequestReader _requests = RtspRequestReader();
  final TimingClient _timing = TimingClient();
  final List<RawDatagramSocket> _audioSockets = [];

  Future<void> _queue = Future.value();
  Uint8List? _sessionKey;
  bool _admitted = false;
  String _deviceName = 'iPhone';
  String? _deviceId;
  ServerSocket? _videoServer;
  Socket? _videoSocket;
  MirrorPacketReader _packets = MirrorPacketReader();
  MirrorStreamDecoder? _decoder;
  AirPlayFeed? _feed;
  Timer? _idleTimer;
  Timer? _graceTimer;
  DateTime _lastHeard = DateTime.now();
  bool _closed = false;

  void start() {
    _socket.listen(
      _onControlBytes,
      onDone: () => unawaited(_onControlClosed()),
      onError: (Object _) => unawaited(_onControlClosed()),
      cancelOnError: true,
    );
  }

  /// Ends the feed, if one runs, with [reason] and closes everything.
  Future<void> close([FeedEnd reason = .lostConnection]) async {
    if (_closed) {
      return;
    }

    _closed = true;
    _feed?.end(reason);
    _idleTimer?.cancel();
    _graceTimer?.cancel();
    _timing.stop();
    for (final socket in _audioSockets) {
      socket.close();
    }

    _audioSockets.clear();
    _videoSocket?.destroy();
    await _videoServer?.close();
    _socket.destroy();
    onClosed(this);
  }

  void _onControlBytes(Uint8List chunk) {
    _lastHeard = DateTime.now();
    final List<RtspRequest> requests;
    try {
      requests = _requests.add(chunk);
    } on FormatException {
      unawaited(close(.failed));
      return;
    }

    for (final request in requests) {
      _queue = _queue.then((_) => _respond(request));
    }
  }

  Future<void> _onControlClosed() => close();

  Future<void> _respond(RtspRequest request) async {
    if (_closed) {
      return;
    }

    RtspResponse response;
    try {
      response = await _handle(request);
    } on Object catch (error) {
      printWarning('AirPlay ${request.method} failed', error.runtimeType);
      response = RtspResponse(status: 500, reason: 'Internal Server Error');
    }

    if (_closed) {
      return;
    }

    _socket.add(response.encodeFor(request));
    if (response.closeAfter) {
      await _socket.flush().catchError((Object _) {});
      await close(.stoppedThere);
    }
  }

  Future<RtspResponse> _handle(RtspRequest request) async =>
      switch ((request.method, request.path)) {
        ('GET', '/info') => _info(request),
        ('POST', '/pair-setup') => await _pairSetup(request),
        ('POST', '/pair-verify') => await _pairVerifyStep(request),
        ('POST', '/fp-setup') => _fairPlaySetup(request),
        ('SETUP', _) => await _setup(request),
        ('GET_PARAMETER', _) => _getParameter(request),
        ('RECORD', _) => RtspResponse(
          headers: {
            'Audio-Latency': '11025',
            'Audio-Jack-Status': 'connected; type=analog',
          },
        ),
        ('OPTIONS', _) => RtspResponse(
          headers: {
            'Public':
                'SETUP, RECORD, FLUSH, TEARDOWN, OPTIONS, '
                'GET_PARAMETER, SET_PARAMETER',
          },
        ),
        ('TEARDOWN', _) => _teardown(request),
        // SET_PARAMETER, FLUSH, /feedback, /audioMode: nothing to do for
        // a receiver that only shows the picture.
        _ => RtspResponse(),
      };

  RtspResponse _info(RtspRequest request) {
    final asked = BinaryPlistDecoder.decodeDict(request.body)['qualifier'];
    final qualifiers = switch (asked) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    return RtspResponse.plist(info.toInfo(qualifiers: qualifiers));
  }

  Future<RtspResponse> _pairSetup(RtspRequest request) async {
    if (request.body.length != PairVerify.keyLength) {
      return RtspResponse.badRequest();
    }

    return RtspResponse.bytes(info.publicKey);
  }

  Future<RtspResponse> _pairVerifyStep(RtspRequest request) async {
    final body = request.body;
    const keysEnd = 4 + PairVerify.keyLength * 2;
    if (body.length == keysEnd && body[0] == 1) {
      final answer = await _pairVerify.start(
        body.sublist(4, 4 + PairVerify.keyLength),
        body.sublist(4 + PairVerify.keyLength, keysEnd),
      );
      return RtspResponse.bytes(answer);
    }

    if (body.length == 4 + PairVerify.signatureLength && body[0] == 0) {
      final verified = await _pairVerify.finish(body.sublist(4));
      if (!verified) {
        return RtspResponse(
          status: 470,
          reason: 'Connection Authorization Required',
          closeAfter: true,
        );
      }

      return RtspResponse.bytes(Uint8List(0));
    }

    return RtspResponse.badRequest();
  }

  RtspResponse _fairPlaySetup(RtspRequest request) {
    final answer = _fairPlay.answer(request.body);
    if (answer == null) {
      return RtspResponse.badRequest();
    }

    return RtspResponse.bytes(answer);
  }

  Future<RtspResponse> _setup(RtspRequest request) async {
    final dict = BinaryPlistDecoder.decodeDict(request.body);
    final answer = <String, Object?>{};
    if (dict case {'ekey': final Uint8List encryptedKey, 'eiv': Uint8List _}) {
      final refusal = await _setupSession(dict, encryptedKey, answer);
      if (refusal != null) {
        return refusal;
      }
    }

    if (dict['streams'] case final List<Object?> streams) {
      if (!_admitted) {
        return RtspResponse.unauthorized();
      }

      final opened = <Map<String, Object?>>[];
      for (final stream in streams) {
        if (await _setupStream(stream) case final description?) {
          opened.add(description);
        }
      }

      answer['streams'] = opened;
    }

    return RtspResponse.plist(answer);
  }

  /// The first SETUP: the phone names itself and sends the session key.
  /// This is where the owner of this computer is asked. Returns the
  /// refusal to send, or null when the session may go on.
  Future<RtspResponse?> _setupSession(
    Map<String, Object?> dict,
    Uint8List encryptedKey,
    Map<String, Object?> answer,
  ) async {
    final fairPlayKey = _fairPlay.decryptKey(encryptedKey);
    if (fairPlayKey == null) {
      return RtspResponse.badRequest();
    }

    if (dict['name'] case final String name) {
      _deviceName = _cleanName(name);
    }

    if (dict['deviceID'] case final String deviceId) {
      _deviceId = _cleanName(deviceId);
    }

    final allowed = await _ask();
    if (!allowed || _closed) {
      return RtspResponse.unauthorized();
    }

    _admitted = true;
    _sessionKey = MirrorStreamKeys.sessionKey(
      fairPlayKey,
      _pairVerify.sharedSecret,
    );
    final timingPort = switch (dict['timingPort']) {
      final int port when port > 0 && port < 65536 => port,
      _ => 0,
    };
    _timing.stop();
    answer['timingPort'] = await _timing.start(_remote, timingPort);
    answer['eventPort'] = 0;
    if (_closed) {
      _timing.stop();
    }

    return null;
  }

  Future<bool> _ask() async {
    try {
      return await allow(_deviceName).timeout(
        askTimeout,
        onTimeout: () => false,
      );
    } on Object {
      return false;
    }
  }

  Future<Map<String, Object?>?> _setupStream(Object? stream) async {
    if (stream case {
      'type': _mirrorStream,
      'streamConnectionID': final int connectionId,
    }) {
      return {
        'type': _mirrorStream,
        'dataPort': await _openVideo(connectionId),
      };
    }

    if (stream case {'type': _audioStream}) {
      return {
        'type': _audioStream,
        'dataPort': await _openAudioPort(),
        'controlPort': await _openAudioPort(),
      };
    }

    return null;
  }

  /// Opens the port the phone sends its screen to, and announces the feed.
  Future<int> _openVideo(int connectionId) async {
    final sessionKey = _sessionKey;
    if (sessionKey == null) {
      throw StateError('Stream setup before session setup');
    }

    _feed?.end(.stoppedThere);
    _videoSocket?.destroy();
    _videoSocket = null;
    await _videoServer?.close();

    _graceTimer?.cancel();
    final keys = MirrorStreamKeys.forStream(sessionKey, connectionId);
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    if (_closed) {
      await server.close();
      throw StateError('The phone left during stream setup');
    }

    final feed = AirPlayFeed(
      target: MirrorTarget(
        routeId: routeId,
        id: _deviceId ?? _remote.address,
        name: _deviceName,
        wireless: true,
      ),
      onStop: () => close(.stoppedHere),
    );
    _packets = MirrorPacketReader();
    _decoder = MirrorStreamDecoder(key: keys.key, iv: keys.iv);
    _videoServer = server;
    _feed = feed;
    server.listen(_onVideoSocket, onError: (Object _) {});
    _watchIdle();
    onFeed(feed);
    return server.port;
  }

  /// The phone also sends the screen's sound. It isn't played yet, but
  /// the phone expects somewhere to send it.
  Future<int> _openAudioPort() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    if (_closed) {
      socket.close();
      throw StateError('The phone left during stream setup');
    }

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        socket.receive();
      }
    }, onError: (Object _) {});
    _audioSockets.add(socket);
    return socket.port;
  }

  void _onVideoSocket(Socket socket) {
    if (_closed || _videoSocket != null || socket.remoteAddress != _remote) {
      socket.destroy();
      return;
    }

    _videoSocket = socket;
    socket.listen(
      _onVideoBytes,
      onDone: _onVideoClosed,
      onError: (Object _) => _onVideoClosed(),
      cancelOnError: true,
    );
  }

  void _onVideoBytes(Uint8List chunk) {
    final feed = _feed;
    final decoder = _decoder;
    if (feed == null || decoder == null || feed.isEnded) {
      return;
    }

    _lastHeard = DateTime.now();
    final List<MirrorPacket> packets;
    try {
      packets = _packets.add(chunk);
    } on FormatException {
      unawaited(close(.failed));
      return;
    }

    for (final packet in packets) {
      decoder.add(packet).forEach(feed.add);
    }

    if (feed.isEnded) {
      unawaited(close());
    }
  }

  /// A phone that stops mirroring says TEARDOWN on the control connection
  /// around the time it closes the video one. Only when that doesn't
  /// come was the connection lost.
  void _onVideoClosed() {
    final feed = _feed;
    _graceTimer?.cancel();
    _graceTimer = Timer(_teardownGrace, () => feed?.end(.lostConnection));
  }

  RtspResponse _getParameter(RtspRequest request) {
    final asked = String.fromCharCodes(request.body);
    if (!asked.contains('volume')) {
      return RtspResponse();
    }

    return RtspResponse(
      headers: {'Content-Type': 'text/parameters'},
      body: Uint8List.fromList('volume: 0.000000\r\n'.codeUnits),
    );
  }

  /// With a `streams` list the phone only stops those; without one it
  /// ends the whole session.
  RtspResponse _teardown(RtspRequest request) {
    final streams = BinaryPlistDecoder.decodeDict(request.body)['streams'];
    if (streams is! List<Object?>) {
      return RtspResponse(headers: {'Connection': 'close'}, closeAfter: true);
    }

    final stopsVideo = streams.any(
      (stream) => switch (stream) {
        {'type': _mirrorStream} => true,
        _ => false,
      },
    );
    if (stopsVideo) {
      _feed?.end(.stoppedThere);
      _videoSocket?.destroy();
      _videoSocket = null;
    }

    return RtspResponse(headers: {'Connection': 'close'});
  }

  void _watchIdle() {
    _idleTimer?.cancel();
    _lastHeard = DateTime.now();
    _idleTimer = .periodic(const Duration(seconds: 5), (_) {
      final feed = _feed;
      if (feed == null || feed.isEnded) {
        return;
      }

      if (DateTime.now().difference(_lastHeard) > idleTimeout) {
        unawaited(close());
      }
    });
  }

  /// The phone's name is shown to the user: keep it short and printable.
  String _cleanName(String name) {
    final printable = String.fromCharCodes(
      name.runes.where((rune) => rune >= 0x20 && rune != 0x7f),
    ).trim();
    if (printable.length <= _maxNameLength) {
      return printable;
    }

    return printable.substring(0, _maxNameLength);
  }
}
