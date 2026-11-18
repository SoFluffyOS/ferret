import 'dart:async';
import 'dart:convert';

import 'package:engine/engine.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/browser/attempt_limiter.dart';
import 'package:handoff/services/browser/browser_bridge_server.dart';
import 'package:handoff/services/browser/browser_channel.dart';
import 'package:handoff/services/browser/browser_client_store.dart';
import 'package:handoff/services/browser/browser_connection.dart';
import 'package:handoff/services/browser/browser_origin.dart';
import 'package:handoff/services/browser/browser_tab_opener.dart';
import 'package:handoff/services/browser/browser_token.dart';
import 'package:handoff/services/browser/extension_tab.dart';
import 'package:handoff/services/handoff_settings.dart';
import 'package:handoff/services/link_rules.dart';
import 'package:handoff/services/recent_publishes.dart';
import 'package:protocol/handoff.dart';

/// Lets the Ferret browser extension use Handoff on this computer: it pairs
/// the extension with a code the user confirms, then turns its messages into
/// sends and passive publishes, and pushes suggestions and "open here"
/// requests back. The wire format is in `extensions/browser/PROTOCOL.md`.
class BrowserBridge implements BrowserTabOpener {
  BrowserBridge({
    required this.feature,
    required this.isSupported,
    BrowserBridgeServer? server,
    RecentPublishes? recentPublishes,
    AttemptLimiter? limiter,
    DateTime Function()? clock,
    this.pairTimeout = const Duration(minutes: 2),
    this.openTimeout = const Duration(seconds: 3),
  }) : _server = server ?? BrowserBridgeServer(),
       _recent = recentPublishes ?? RecentPublishes(clock: clock),
       _now = clock ?? DateTime.now,
       _limiter =
           limiter ??
           AttemptLimiter(
             maxAttempts: 10,
             window: const Duration(minutes: 1),
             clock: clock,
           );

  static const protocolVersion = 1;
  static const maxMessageLength = 64 * 1024;
  static const maxPendingPairs = 3;
  static const _maxStrikes = 5;
  static const _maxIdLength = 64;
  static const _maxBrowserName = 32;
  static final _sixDigits = RegExp(r'^\d{6}$');
  static final _controlCharacters = RegExp(r'[\x00-\x1F\x7F]');

  final HandoffFeature feature;

  /// Desktops only: phones have no browser extensions to talk to.
  final bool isSupported;
  final Duration pairTimeout;
  final Duration openTimeout;

  final BrowserBridgeServer _server;
  final RecentPublishes _recent;
  final DateTime Function() _now;
  final AttemptLimiter _limiter;
  final Set<BrowserConnection> _connections = {};
  final Map<String, _PendingPair> _pairs = {};
  final Map<String, _PendingOpen> _opens = {};
  final StreamController<void> _changes = .broadcast();
  final StreamController<BrowserPairRequest> _pairRequested = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final BrowserClientStore _store = BrowserClientStore(_host.settings);
  BrowserBridgeState _state = BrowserBridgeState.off;
  bool _started = false;

  FeatureHost get _host => feature.host;

  /// Fires when pair requests, paired browsers or the bridge state change.
  Stream<void> get changes => _changes.stream;

  /// A browser asked to pair, to show and bring Ferret forward.
  Stream<BrowserPairRequest> get pairRequested => _pairRequested.stream;

  BrowserBridgeState get state => _state;

  List<BrowserPairRequest> get pairRequests => [
    for (final pair in _pairs.values) pair.request,
  ];

  List<BrowserClient> get clients => _store.clients;

  bool get isEnabled =>
      _host.settings.get<bool>(HandoffSettings.browserBridge) ??
      HandoffSettings.browserBridgeDefault;

  /// Paired browsers connected right now, by client id.
  Set<String> get connectedClientIds => {
    for (final connection in _connections)
      if (connection.client case final client?) client.id,
  };

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;
    _subscriptions
      ..add(feature.changes.listen((_) => _pushSuggestions()))
      ..add(_host.sessionChanges.listen((_) => _pushDevices()))
      ..add(_host.trustStore.changes.listen((_) => _pushDevices()));
    await refresh();
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    _started = false;
    await _closeServer();
  }

  /// Starts or stops listening to match the setting.
  Future<void> refresh() async {
    if (!isSupported || !isEnabled) {
      await _closeServer();
      return;
    }

    final port = await _server.start(attach);
    _setState(switch (port) {
      final port? => BrowserBridgeState(.listening, port: port),
      null => const BrowserBridgeState(.failed),
    });
  }

  Future<void> setEnabled(bool enabled) async {
    await _host.settings.set(HandoffSettings.browserBridge, enabled);
    await refresh();
  }

  /// Takes a connection the server accepted.
  void attach(BrowserChannel channel) {
    final connection = BrowserConnection(
      channel,
      browser: BrowserOrigin.familyOf(channel.origin),
    );
    _connections.add(connection);
    _expectPairingWithin(connection, pairTimeout);
    channel.messages.listen(
      (text) => unawaited(_onMessage(connection, text)),
      onDone: () => _onClosed(connection),
    );
  }

  /// The user allowed or denied a browser.
  Future<void> answerPair(String requestId, {required bool allow}) async {
    final pair = _pairs.remove(requestId);
    if (pair == null) {
      return;
    }

    pair.timer.cancel();
    _changes.add(null);
    if (pair.connection.closed) {
      return;
    }

    if (!allow) {
      _send(pair.connection, {
        'type': 'pair_denied',
        're': pair.replyTo,
        'reason': 'denied',
      });
      return;
    }

    final token = BrowserToken.create();
    final client = BrowserClient(
      id: BrowserToken.newId(),
      name: pair.request.browser,
      origin: pair.connection.channel.origin,
      tokenHash: BrowserToken.hash(token),
      pairedAt: _now(),
    );
    await _store.add(client);
    _authenticate(pair.connection, client);
    _send(pair.connection, {
      'type': 'paired',
      're': pair.replyTo,
      'token': token,
      'client': client.id,
      'device': _host.localDevice.name,
    });
    _pushDevices(only: pair.connection);
    _pushSuggestions(only: pair.connection, force: true);
    _changes.add(null);
  }

  /// Forgets a browser; its extension has to pair again.
  Future<void> removeClient(String clientId) async {
    if (!await _store.remove(clientId)) {
      return;
    }

    for (final connection in _connections.toList()) {
      if (connection.client?.id != clientId) {
        continue;
      }

      _send(connection, {'type': 'revoked'});
      await _close(connection, BrowserCloseCode.revoked, 'revoked');
    }

    _changes.add(null);
  }

  @override
  Future<bool> openInBrowser(Activity activity) async {
    if (activity.kind != .ACTIVITY_KIND_WEB || !LinkRules.isWeb(activity.uri)) {
      return false;
    }

    final target = _focusedBrowser();
    if (target == null) {
      return false;
    }

    final id = BrowserToken.newId();
    final answer = Completer<bool>();
    _opens[id] = _PendingOpen(target, answer);
    final position = ExtensionTab.positionOf(activity);
    _send(target, {
      'type': 'open',
      'id': id,
      'url': activity.uri,
      'title': activity.title,
      'videoTime': ?position.videoTime,
      'scrollY': ?position.scrollY,
    });

    final opened = await answer.future.timeout(
      openTimeout,
      onTimeout: () => false,
    );
    _opens.remove(id);
    return opened;
  }

  BrowserConnection? _focusedBrowser() {
    BrowserConnection? latest;
    for (final connection in _connections) {
      if (!connection.isPaired || !connection.focused || connection.closed) {
        continue;
      }

      if (latest == null ||
          connection.focusChangedAt.isAfter(latest.focusChangedAt)) {
        latest = connection;
      }
    }

    return latest;
  }

  Future<void> _onMessage(BrowserConnection connection, String text) async {
    if (connection.closed) {
      return;
    }

    if (text.length > maxMessageLength) {
      await _close(connection, BrowserCloseCode.tooLarge, 'too large');
      return;
    }

    final message = _decode(text);
    if (message == null) {
      await _strike(connection, null, 'bad_request');
      return;
    }

    final replyTo = switch (message['id']) {
      final String id when id.isNotEmpty && id.length <= _maxIdLength => id,
      _ => null,
    };
    final type = message['type'];

    if (type == 'ping') {
      _send(connection, {'type': 'pong', 're': replyTo});
      return;
    }

    if (type == 'hello') {
      await _hello(connection, message, replyTo);
      return;
    }

    if (!connection.greeted) {
      _error(connection, replyTo, 'hello_first');
      await _close(connection, BrowserCloseCode.protocolError, 'hello first');
      return;
    }

    if (type == 'pair') {
      await _pair(connection, message, replyTo);
      return;
    }

    if (!await _isAuthorized(connection, message, replyTo)) {
      return;
    }

    switch (type) {
      case 'devices':
        _send(connection, {
          'type': 'devices',
          're': replyTo,
          'devices': _devices(),
        });
      case 'suggestions':
        _send(connection, {
          'type': 'suggestions',
          're': replyTo,
          'items': _suggestions(),
        });
      case 'send':
        await _sendTab(connection, message, replyTo);
      case 'share':
        await _shareTab(connection, message, replyTo);
      case 'focus':
        connection
          ..focused = message['focused'] == true
          ..focusChangedAt = _now();
      case 'dismiss':
        if (message['activityId'] case final String activityId) {
          feature.dismiss(activityId);
        }
      case 'opened':
        if (message['re'] case final String openId) {
          final pending = _opens[openId];
          if (pending != null &&
              pending.connection == connection &&
              !pending.answer.isCompleted) {
            pending.answer.complete(message['ok'] == true);
          }
        }
      case 'unpair':
        await _unpair(connection, replyTo);
      default:
        await _strike(connection, replyTo, 'unknown_type');
    }
  }

  Future<void> _hello(
    BrowserConnection connection,
    Map<String, Object?> message,
    String? replyTo,
  ) async {
    if (message['v'] != protocolVersion) {
      _send(connection, {
        'type': 'error',
        're': replyTo,
        'code': 'unsupported_version',
        'v': protocolVersion,
      });
      await _close(connection, BrowserCloseCode.protocolError, 'version');
      return;
    }

    connection
      ..greeted = true
      ..browser = _browserName(message['browser'], connection.channel.origin);

    if (message['token'] case final String token when token.isNotEmpty) {
      final client = _store.find(
        token: token,
        origin: connection.channel.origin,
      );
      if (client == null && !await _countAttempt(connection, replyTo)) {
        return;
      }

      if (client != null) {
        _authenticate(connection, client);
      }
    }

    _send(connection, {
      'type': 'welcome',
      're': replyTo,
      'v': protocolVersion,
      'app': 'ferret',
      'device': _host.localDevice.name,
      'paired': connection.isPaired,
      'passive': feature.passiveEnabled,
    });

    if (!connection.isPaired) {
      return;
    }

    _pushDevices(only: connection);
    _pushSuggestions(only: connection, force: true);
  }

  Future<void> _pair(
    BrowserConnection connection,
    Map<String, Object?> message,
    String? replyTo,
  ) async {
    final code = switch (message['code']) {
      final String code when _sixDigits.hasMatch(code) => code,
      _ => null,
    };
    if (code == null) {
      await _strike(connection, replyTo, 'bad_request');
      return;
    }

    final busy =
        _pairs.length >= maxPendingPairs ||
        _pairs.values.any((pair) => pair.connection == connection);
    if (busy) {
      _send(connection, {
        'type': 'pair_denied',
        're': replyTo,
        'reason': 'busy',
      });
      return;
    }

    if (!await _countAttempt(connection, replyTo)) {
      return;
    }

    if (message['browser'] case final Object name) {
      connection.browser = _browserName(name, connection.channel.origin);
    }

    final request = BrowserPairRequest(
      id: BrowserToken.newId(),
      browser: connection.browser,
      code: code,
      requestedAt: _now(),
    );
    _pairs[request.id] = _PendingPair(
      request: request,
      connection: connection,
      replyTo: replyTo,
      timer: Timer(pairTimeout, () => _expirePair(request.id)),
    );
    _expectPairingWithin(connection, pairTimeout + const Duration(seconds: 30));
    _changes.add(null);
    _pairRequested.add(request);
  }

  void _expirePair(String requestId) {
    final pair = _pairs.remove(requestId);
    if (pair == null) {
      return;
    }

    _send(pair.connection, {
      'type': 'pair_denied',
      're': pair.replyTo,
      'reason': 'timeout',
    });
    _changes.add(null);
  }

  Future<bool> _isAuthorized(
    BrowserConnection connection,
    Map<String, Object?> message,
    String? replyTo,
  ) async {
    final client = connection.client;
    final token = message['token'];
    final valid =
        client != null &&
        token is String &&
        BrowserToken.matches(token, client.tokenHash) &&
        _store.byId(client.id) != null;
    if (valid) {
      return true;
    }

    if (!await _countAttempt(connection, replyTo)) {
      return false;
    }

    _error(connection, replyTo, 'unauthorized');
    return false;
  }

  /// Counts one unauthenticated attempt. False (and the connection closed)
  /// once there were too many lately.
  Future<bool> _countAttempt(
    BrowserConnection connection,
    String? replyTo,
  ) async {
    if (_limiter.tryAcquire()) {
      return true;
    }

    _send(connection, {
      'type': 'error',
      're': replyTo,
      'code': 'rate_limited',
      'retryAfterMs': _limiter.retryAfter.inMilliseconds,
    });
    await _close(connection, BrowserCloseCode.rateLimited, 'rate limited');
    return false;
  }

  Future<void> _sendTab(
    BrowserConnection connection,
    Map<String, Object?> message,
    String? replyTo,
  ) async {
    final tab = ExtensionTab.fromJson(message['tab']);
    final deviceId = switch (message['deviceId']) {
      final String id when id.isNotEmpty => id,
      _ => null,
    };
    if (tab == null || deviceId == null) {
      await _strike(connection, replyTo, 'bad_request');
      return;
    }

    final outcome = await feature.sendTo(
      deviceId,
      tab.toActivity(browser: connection.browser),
    );
    _send(connection, {'type': 'sent', 're': replyTo, 'outcome': outcome.name});
  }

  Future<void> _shareTab(
    BrowserConnection connection,
    Map<String, Object?> message,
    String? replyTo,
  ) async {
    final tab = ExtensionTab.fromJson(message['tab']);
    if (tab == null) {
      await _strike(connection, replyTo, 'bad_request');
      return;
    }

    var delivered = 0;
    if (!_recent.isRecent(tab.url, feature.passiveLifetime)) {
      _recent.mark(tab.url);
      delivered = await feature.publish(
        tab.toActivity(browser: connection.browser),
      );
    }

    _send(connection, {
      'type': 'shared',
      're': replyTo,
      'delivered': delivered,
    });
  }

  Future<void> _unpair(BrowserConnection connection, String? replyTo) async {
    if (connection.client case final client?) {
      await _store.remove(client.id);
    }

    _send(connection, {'type': 'unpaired', 're': replyTo});
    await _close(connection, BrowserCloseCode.goingAway, 'unpaired');
    _changes.add(null);
  }

  List<Map<String, Object?>> _devices() {
    final sessions = {
      for (final session in _host.sessions) session.remoteDeviceId: session,
    };
    return [
      for (final device in _host.trustStore.devices)
        {
          'id': device.id,
          'name': device.name,
          'platform': _shortName(device.platform.name, 'PLATFORM_'),
          'formFactor': _shortName(device.formFactor.name, 'FORM_FACTOR_'),
          'connected':
              sessions[device.id]?.supports(HandoffFeature.featureId) ?? false,
        },
    ];
  }

  List<Map<String, Object?>> _suggestions() => [
    for (final suggestion in feature.suggestions)
      if (suggestion.activity.kind == .ACTIVITY_KIND_WEB &&
          LinkRules.isWeb(suggestion.activity.uri))
        _suggestionJson(suggestion),
  ];

  Map<String, Object?> _suggestionJson(Suggestion suggestion) {
    final position = ExtensionTab.positionOf(suggestion.activity);
    return {
      'id': suggestion.id,
      'title': suggestion.activity.title,
      'url': suggestion.activity.uri,
      'from': suggestion.from.name,
      'fromId': suggestion.from.id,
      'explicit': suggestion.isExplicit,
      'receivedAtMs': suggestion.receivedAt.millisecondsSinceEpoch,
      'expiresAtMs': suggestion.expiresAt.millisecondsSinceEpoch,
      'videoTime': ?position.videoTime,
      'scrollY': ?position.scrollY,
    };
  }

  void _pushDevices({BrowserConnection? only}) {
    final devices = _devices();
    for (final connection in _pairedConnections(only)) {
      _send(connection, {'type': 'devices', 'devices': devices});
    }
  }

  /// Pushes suggestions to browsers only when the list changed, so a timer
  /// tick or a timeline update doesn't make the badge flicker.
  void _pushSuggestions({BrowserConnection? only, bool force = false}) {
    final items = _suggestions();
    final key = [for (final item in items) item['id']].join(',');
    for (final connection in _pairedConnections(only)) {
      if (!force && connection.suggestionsKey == key) {
        continue;
      }

      connection.suggestionsKey = key;
      _send(connection, {'type': 'suggestions', 'items': items});
    }
  }

  Iterable<BrowserConnection> _pairedConnections(BrowserConnection? only) {
    if (only != null) {
      return [only];
    }

    return _connections.where((connection) => connection.isPaired);
  }

  void _authenticate(BrowserConnection connection, BrowserClient client) {
    connection
      ..client = client
      ..unpairedTimer?.cancel()
      ..unpairedTimer = null;
    _changes.add(null);
  }

  /// Unpaired connections only get so long to pair, so a stray tab of the
  /// extension can't hold a slot forever.
  void _expectPairingWithin(BrowserConnection connection, Duration limit) {
    connection.unpairedTimer?.cancel();
    connection.unpairedTimer = Timer(limit, () {
      if (connection.isPaired) {
        return;
      }

      unawaited(_close(connection, BrowserCloseCode.unauthorized, 'pair'));
    });
  }

  Future<void> _strike(
    BrowserConnection connection,
    String? replyTo,
    String code,
  ) async {
    connection.strikes++;
    _error(connection, replyTo, code);
    if (connection.strikes < _maxStrikes) {
      return;
    }

    await _close(connection, BrowserCloseCode.protocolError, 'too many errors');
  }

  void _error(BrowserConnection connection, String? replyTo, String code) =>
      _send(connection, {'type': 'error', 're': replyTo, 'code': code});

  void _send(BrowserConnection connection, Map<String, Object?> message) {
    if (connection.closed) {
      return;
    }

    message.removeWhere((_, value) => value == null);
    connection.channel.send(message);
  }

  Future<void> _close(
    BrowserConnection connection,
    int code,
    String reason,
  ) async {
    if (connection.closed) {
      return;
    }

    _onClosed(connection);
    await connection.channel.close(code, reason);
  }

  void _onClosed(BrowserConnection connection) {
    if (connection.closed) {
      return;
    }

    connection
      ..closed = true
      ..unpairedTimer?.cancel();
    final wasPaired = _connections.remove(connection) && connection.isPaired;

    final abandoned = [
      for (final MapEntry(:key, :value) in _pairs.entries)
        if (value.connection == connection) key,
    ];
    for (final requestId in abandoned) {
      _pairs.remove(requestId)?.timer.cancel();
    }

    for (final pending in _opens.values) {
      if (pending.connection == connection && !pending.answer.isCompleted) {
        pending.answer.complete(false);
      }
    }

    if (abandoned.isNotEmpty || wasPaired) {
      _changes.add(null);
    }
  }

  Future<void> _closeServer() async {
    for (final connection in _connections.toList()) {
      await _close(connection, BrowserCloseCode.goingAway, 'off');
    }

    for (final pair in _pairs.values) {
      pair.timer.cancel();
    }

    _pairs.clear();
    await _server.stop();
    _setState(BrowserBridgeState.off);
  }

  void _setState(BrowserBridgeState state) {
    if (_state.status == state.status && _state.port == state.port) {
      return;
    }

    _state = state;
    _changes.add(null);
  }

  static Map<String, Object?>? _decode(String text) {
    try {
      if (jsonDecode(text) case final Map<String, Object?> message) {
        return message;
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  static String _browserName(Object? name, String origin) {
    final cleaned = switch (name) {
      final String value => value.replaceAll(_controlCharacters, '').trim(),
      _ => '',
    };
    if (cleaned.isEmpty) {
      return BrowserOrigin.familyOf(origin);
    }

    if (cleaned.length <= _maxBrowserName) {
      return cleaned;
    }

    return cleaned.substring(0, _maxBrowserName);
  }

  static String _shortName(String name, String prefix) =>
      name.replaceFirst(prefix, '').toLowerCase();
}

class _PendingPair {
  const _PendingPair({
    required this.request,
    required this.connection,
    required this.replyTo,
    required this.timer,
  });

  final BrowserPairRequest request;
  final BrowserConnection connection;
  final String? replyTo;
  final Timer timer;
}

class _PendingOpen {
  const _PendingOpen(this.connection, this.answer);

  final BrowserConnection connection;
  final Completer<bool> answer;
}
