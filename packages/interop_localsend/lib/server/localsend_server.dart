import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:interop_localsend/models/models.dart';
import 'package:interop_localsend/security/security.dart';
import 'package:interop_localsend/server/local_networks.dart';
import 'package:interop_localsend/server/localsend_offer.dart';
import 'package:interop_localsend/server/localsend_receive_delegate.dart';
import 'package:interop_localsend/server/localsend_session_end.dart';
import 'package:interop_localsend/server/receive_session.dart';

/// The receiving side of LocalSend: an HTTPS server with the upload API
/// (`/register`, `/info`, `/prepare-upload`, `/upload`, `/cancel`).
///
/// It serves one session at a time, only to addresses on the local
/// network, and only while it runs: nothing listens until [start].
class LocalSendServer {
  LocalSendServer({
    required this.identity,
    required this.self,
    required this.delegate,
    this.port = LocalSendDefaults.port,
    this.fallbackPorts = 8,
    this.pin,
    this.onRegister,
    this.idleTimeout = const Duration(seconds: 60),
    InternetAddress? address,
  }) : _address = address ?? InternetAddress.anyIPv4;

  static const maxPinAttempts = 3;
  static const _maxJsonBytes = 8 * 1024 * 1024;
  static final _random = Random.secure();

  final LocalSendIdentity identity;

  /// This device's description, given the port the server listens on.
  final LocalSendInfo Function(int port) self;
  final LocalSendReceiveDelegate delegate;

  /// The port to try first. When it is taken, such as by the LocalSend app
  /// itself, the next [fallbackPorts] are tried, then any free port.
  final int port;
  final int fallbackPorts;

  /// When it returns a PIN, senders must add it to `/prepare-upload`.
  final String? Function()? pin;

  /// Another member introduced itself through `/register`.
  final void Function(LocalSendInfo info, InternetAddress address)? onRegister;

  /// How long an accepted session may sit without any upload before it is
  /// given up.
  final Duration idleTimeout;

  final InternetAddress _address;
  final Map<String, int> _pinFailures = {};
  HttpServer? _server;
  ReceiveSession? _session;
  Timer? _idleTimer;

  bool get isRunning => _server != null;

  /// The port the server listens on, or null when it is stopped.
  int? get boundPort => _server?.port;

  /// Whether an offer is waiting or files are arriving.
  bool get isBusy => _session != null;

  /// Starts listening and returns the port. Throws a [SocketException]
  /// when no port could be bound.
  Future<int> start() async {
    if (_server case final running?) {
      return running.port;
    }

    final server = await _bind();
    server
      ..autoCompress = false
      ..listen(
        (request) => unawaited(_serve(request)),
        onError: (Object error) =>
            printDebug('LocalSend server: ${error.runtimeType}'),
      );
    _server = server;
    _idleTimer = .periodic(const Duration(seconds: 5), (_) => _checkIdle());
    return server.port;
  }

  /// Stops listening. A session in progress ends as cancelled by this
  /// device.
  Future<void> stop() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final server = _server;
    _server = null;
    if (_session case final session?) {
      await _close(session);
    }

    await server?.close(force: true);
    _pinFailures.clear();
  }

  /// Cancels [sessionId] from this device: uploads stop and later ones are
  /// refused.
  Future<void> cancelSession(String sessionId) async {
    final session = _session;
    if (session == null || session.offer.sessionId != sessionId) {
      return;
    }

    await _close(session);
  }

  Future<HttpServer> _bind() async {
    final context = identity.securityContext();
    for (var offset = 0; offset <= fallbackPorts; offset++) {
      try {
        return await HttpServer.bindSecure(_address, port + offset, context);
      } on SocketException {
        continue;
      }
    }

    return HttpServer.bindSecure(_address, 0, context);
  }

  Future<void> _serve(HttpRequest request) async {
    try {
      await _route(request);
    } on Object catch (error) {
      printWarning('LocalSend request failed: ${error.runtimeType}');
      await _respond(request, HttpStatus.internalServerError);
    }
  }

  Future<void> _route(HttpRequest request) async {
    final remote = request.connectionInfo?.remoteAddress;
    if (remote == null || !LocalNetworks.contains(remote)) {
      return _respond(request, HttpStatus.forbidden);
    }

    const prefix = '${LocalSendDefaults.apiPath}/';
    final path = request.uri.path;
    if (!path.startsWith(prefix)) {
      return _respond(request, HttpStatus.notFound);
    }

    return switch ((request.method, path.substring(prefix.length))) {
      ('POST', 'register') => _register(request, remote),
      ('GET', 'info') => _respondJson(request, _self().toAnswerJson()),
      ('POST', 'prepare-upload') => _prepareUpload(request, remote),
      ('POST', 'upload') => _upload(request, remote),
      ('POST', 'cancel') => _cancel(request, remote),
      _ => _respond(request, HttpStatus.notFound),
    };
  }

  Future<void> _register(HttpRequest request, InternetAddress remote) async {
    final info = LocalSendInfo.fromJson(await _readJson(request));
    if (info == null) {
      return _respond(request, HttpStatus.badRequest);
    }

    onRegister?.call(info, remote);
    return _respondJson(request, _self().toAnswerJson());
  }

  Future<void> _prepareUpload(
    HttpRequest request,
    InternetAddress remote,
  ) async {
    final pinStatus = _checkPin(request, remote);
    if (pinStatus != null) {
      await request.drain<void>();
      return _respond(request, pinStatus);
    }

    final prepared = PrepareUploadRequest.fromJson(await _readJson(request));
    if (prepared == null) {
      return _respond(request, HttpStatus.badRequest);
    }

    if (_session != null) {
      return _respond(request, HttpStatus.conflict);
    }

    final offer = LocalSendOffer(
      sessionId: _randomId(),
      sender: prepared.info,
      address: remote,
      files: [...prepared.files.values],
    );
    final session = ReceiveSession(offer);
    _session = session;

    final Set<String>? accepted;
    try {
      accepted = await delegate.onOffer(offer);
    } on Object {
      _forget(session);
      rethrow;
    }

    if (session.isEnded) {
      return _respond(request, HttpStatus.forbidden);
    }

    if (accepted == null) {
      _forget(session);
      return _respond(request, HttpStatus.forbidden);
    }

    final wanted = [
      for (final file in offer.files)
        if (accepted.contains(file.id)) file.id,
    ];
    if (wanted.isEmpty) {
      _forget(session);
      return _respond(request, HttpStatus.noContent);
    }

    for (final fileId in wanted) {
      session.tokens[fileId] = _randomId();
    }

    session
      ..isPending = false
      ..lastActivity = DateTime.now();
    return _respondJson(
      request,
      PrepareUploadResponse(
        sessionId: offer.sessionId,
        files: session.tokens,
      ).toJson(),
    );
  }

  Future<void> _upload(HttpRequest request, InternetAddress remote) async {
    final query = request.uri.queryParameters;
    final (sessionId, fileId, token) = (
      query['sessionId'],
      query['fileId'],
      query['token'],
    );
    if (sessionId == null || fileId == null || token == null) {
      return _respond(request, HttpStatus.badRequest);
    }

    final session = _session;
    if (session == null || session.isPending) {
      return _respond(request, HttpStatus.forbidden);
    }

    if (session.offer.sessionId != sessionId) {
      return _respond(request, HttpStatus.conflict);
    }

    final allowed =
        session.offer.address == remote &&
        session.tokens[fileId] == token &&
        !session.saved.contains(fileId) &&
        !session.uploads.containsKey(fileId);
    if (!allowed) {
      return _respond(request, HttpStatus.forbidden);
    }

    final file = session.offer.files.firstWhere((file) => file.id == fileId);
    final part = await delegate.partFile(session.offer, file);
    final status = await _receive(request, session, file, part);
    if (status != HttpStatus.ok) {
      session.received[fileId] = 0;
      await _deleteQuietly(part);
      if (!session.isEnded) {
        delegate.onProgress(session.offer, session.receivedBytes);
      }

      return _respond(request, status);
    }

    try {
      await delegate.onFileReceived(session.offer, file, part);
    } on Object catch (error) {
      printWarning('LocalSend could not save a file: ${error.runtimeType}');
      await _deleteQuietly(part);
      await _end(session, .storageFailed);
      return _respond(request, HttpStatus.internalServerError);
    }

    session
      ..saved.add(fileId)
      ..lastActivity = DateTime.now();
    await _respond(request, HttpStatus.ok);
    if (session.isComplete && !session.isEnded) {
      await _end(session, .finished);
    }
  }

  /// Writes the upload to [part] and checks it against what was announced.
  /// Returns the HTTP status to answer with.
  Future<int> _receive(
    HttpRequest request,
    ReceiveSession session,
    LocalSendFile file,
    File part,
  ) async {
    final digests = _DigestCollector();
    final hasher = sha256.startChunkedConversion(digests);
    final upload = StreamIterator<List<int>>(request);
    session.uploads[file.id] = upload;
    session.received[file.id] = 0;

    RandomAccessFile? output;
    var written = 0;
    try {
      output = await part.open(mode: FileMode.write);
      while (await upload.moveNext()) {
        if (session.isEnded) {
          return HttpStatus.forbidden;
        }

        final chunk = upload.current;
        written += chunk.length;
        if (written > file.size) {
          return HttpStatus.unprocessableEntity;
        }

        await output.writeFrom(chunk);
        hasher.add(chunk);
        session
          ..received[file.id] = written
          ..lastActivity = DateTime.now();
        delegate.onProgress(session.offer, session.receivedBytes);
      }
    } on FileSystemException catch (error) {
      printWarning('LocalSend could not write a file', error.osError);
      return HttpStatus.internalServerError;
    } on IOException {
      return HttpStatus.badRequest;
    } finally {
      session.uploads.remove(file.id);
      await upload.cancel();
      await output?.close();
    }

    if (session.isEnded) {
      return HttpStatus.forbidden;
    }

    hasher.close();
    if (written != file.size) {
      return HttpStatus.unprocessableEntity;
    }

    final promised = file.sha256;
    if (promised != null &&
        !Fingerprints.same(promised, digests.value.toString())) {
      return HttpStatus.unprocessableEntity;
    }

    return HttpStatus.ok;
  }

  Future<void> _cancel(HttpRequest request, InternetAddress remote) async {
    final sessionId = request.uri.queryParameters['sessionId'];
    final session = _session;
    final matches =
        session != null &&
        session.offer.address == remote &&
        (sessionId == null || sessionId == session.offer.sessionId) &&
        (sessionId != null || session.isPending);
    if (session != null && matches) {
      await _end(session, .cancelledBySender);
    }

    return _respond(request, HttpStatus.ok);
  }

  /// Returns the status to refuse with, or null when the PIN is fine.
  int? _checkPin(HttpRequest request, InternetAddress remote) {
    final wanted = pin?.call();
    if (wanted == null || wanted.isEmpty) {
      return null;
    }

    final failures = _pinFailures[remote.address] ?? 0;
    if (failures >= maxPinAttempts) {
      return HttpStatus.tooManyRequests;
    }

    if (request.uri.queryParameters['pin'] == wanted) {
      _pinFailures.remove(remote.address);
      return null;
    }

    _pinFailures[remote.address] = failures + 1;
    return HttpStatus.unauthorized;
  }

  void _checkIdle() {
    final session = _session;
    if (session == null || session.isPending || session.uploads.isNotEmpty) {
      return;
    }

    if (DateTime.now().difference(session.lastActivity) < idleTimeout) {
      return;
    }

    unawaited(_end(session, .stalled));
  }

  /// Ends [session] and tells the delegate why.
  Future<void> _end(ReceiveSession session, LocalSendSessionEnd end) async {
    if (session.isEnded) {
      return;
    }

    await _close(session);
    delegate.onSessionEnded(session.offer, end);
  }

  Future<void> _close(ReceiveSession session) async {
    session.isEnded = true;
    _forget(session);
    await session.abortUploads();
  }

  void _forget(ReceiveSession session) {
    if (identical(_session, session)) {
      _session = null;
    }
  }

  LocalSendInfo _self() => self(boundPort ?? port);

  Future<Object?> _readJson(HttpRequest request) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      if (bytes.length + chunk.length > _maxJsonBytes) {
        return null;
      }

      bytes.addAll(chunk);
    }

    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  Future<void> _respond(HttpRequest request, int status) async {
    try {
      request.response
        ..statusCode = status
        ..contentLength = 0;
      await request.response.close();
    } on Object {
      return;
    }
  }

  Future<void> _respondJson(HttpRequest request, Object json) async {
    final body = utf8.encode(jsonEncode(json));
    try {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..contentLength = body.length
        ..add(body);
      await request.response.close();
    } on Object {
      return;
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      return;
    }
  }

  static String _randomId() => [
    for (var index = 0; index < 16; index++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}

class _DigestCollector implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value ?? sha256.convert(const []);

  @override
  void add(Digest data) => _value = data;

  @override
  void close() {}
}
