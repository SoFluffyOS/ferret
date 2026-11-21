import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/quickshare/quickshare_receiver.dart';
import 'package:drop/services/receive_store.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:interop_quickshare/interop_quickshare.dart';

/// Drop's Quick Share side: makes this device show up in the Quick Share
/// sheet of Android phones for a while, and receives what they send.
///
/// Nothing listens and nothing is announced until [receiveForAWhile].
class QuickShareBridge {
  QuickShareBridge({
    required this.registry,
    required ReceiveStore store,
    required this.settings,
    required this.describeSelf,
    this.options = const QuickShareOptions(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       receiver = QuickShareReceiver(
         registry: registry,
         store: store,
         answerTimeout: options.answerTimeout,
       ) {
    receiver.cancelSession = (sessionId) async =>
        _server?.cancelSession(sessionId);
  }

  static const _busyRecheck = Duration(seconds: 5);

  final TransferRegistry registry;
  final SettingsStore settings;
  final QuickShareOptions options;

  /// This device's name and kind, as phones will show them.
  final ({String name, QuickShareDeviceKind kind}) Function() describeSelf;

  final QuickShareReceiver receiver;

  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  QuickShareServer? _server;
  QuickShareAdvertiser? _advertiser;
  DateTime? _until;
  Timer? _windowTimer;
  QuickShareProblem? _problem;
  bool _starting = false;
  bool _disposed = false;

  /// Fires when the receive state changes.
  Stream<void> get changes => _changes.stream;

  /// Whether Drop offers Quick Share here: only on computers, where phones
  /// have no other built-in way to send. Android phones and tablets have
  /// Quick Share themselves, and iOS keeps the multicast it takes for apps
  /// with a special entitlement.
  bool get isSupported => options.supported ?? _isComputer;

  /// Whether Quick Share is on: by default wherever it is supported.
  bool get isEnabled =>
      isSupported &&
      (settings.get<bool>(DropSettings.quickShareEnabled) ?? _isComputer);

  /// The port phones connect to while this device is visible.
  int? get port => _server?.boundPort;

  QuickShareReceiveState get receiveState => QuickShareReceiveState(
    isOn: _server?.isRunning ?? false,
    isStarting: _starting,
    until: _until,
    name: describeSelf().name,
    problem: _problem,
  );

  /// Makes this device visible for [QuickShareOptions.receiveWindow],
  /// then hides it again.
  Future<void> receiveForAWhile() async {
    if (_disposed || _starting || !isEnabled) {
      return;
    }

    _starting = true;
    _problem = null;
    _emit();
    try {
      await _open();
      _until = _clock().add(options.receiveWindow);
      _armWindow();
    } finally {
      _starting = false;
      _emit();
    }
  }

  /// Turns Quick Share on or off in Drop. Off also hides this device.
  Future<void> setEnabled(bool value) async {
    await settings.set(DropSettings.quickShareEnabled, value);
    if (value) {
      _emit();
      return;
    }

    await stopReceiving();
  }

  /// Hides this device now. Offers waiting for an answer are declined
  /// and running Quick Share receives stop.
  Future<void> stopReceiving() async {
    _windowTimer?.cancel();
    _windowTimer = null;
    _until = null;
    _problem = null;
    await receiver.cancelAll();
    await _close();
    _emit();
  }

  bool owns(String transferId) => receiver.owns(transferId);

  Future<void> cancel(String transferId) => receiver.cancel(transferId);

  Future<void> dispose() async {
    _disposed = true;
    _windowTimer?.cancel();
    await receiver.cancelAll();
    await _close();
    await _changes.close();
  }

  /// Starts the server, then the announcement that points phones to it.
  Future<void> _open() async {
    if (_server?.isRunning ?? false) {
      return;
    }

    final server = QuickShareServer(
      delegate: receiver,
      port: options.port,
      address: options.bindAddress,
      timeouts: options.timeouts,
    );
    final int port;
    try {
      port = await server.start();
    } on SocketException catch (error) {
      printWarning('Quick Share could not listen', error.osError);
      _problem = .cannotListen;
      return;
    }

    if (!options.advertise) {
      _server = server;
      return;
    }

    final advertiser = QuickShareAdvertiser(info: _selfInfo);
    try {
      await advertiser.start(port);
    } on SocketException catch (error) {
      printWarning('Quick Share could not announce itself', error.osError);
      await server.stop();
      _problem = .cannotAdvertise;
      return;
    }

    _server = server;
    _advertiser = advertiser;
  }

  Future<void> _close() async {
    final (server, advertiser) = (_server, _advertiser);
    _server = null;
    _advertiser = null;
    await advertiser?.stop();
    await server?.stop();
  }

  void _armWindow() {
    _windowTimer?.cancel();
    _windowTimer = null;
    final until = _until;
    if (until == null || _server == null) {
      _until = null;
      return;
    }

    final left = until.difference(_clock());
    _windowTimer = Timer(
      switch (left.isNegative) {
        true => Duration.zero,
        false => left,
      },
      () => unawaited(_closeWindow()),
    );
  }

  /// The window ran out. Phones stop seeing this device right away; a
  /// transfer still running gets to finish first.
  Future<void> _closeWindow() async {
    final advertiser = _advertiser;
    _advertiser = null;
    await advertiser?.stop();
    if (_server?.isBusy ?? false) {
      _windowTimer = Timer(_busyRecheck, () => unawaited(_closeWindow()));
      return;
    }

    await stopReceiving();
  }

  QuickShareEndpointInfo _selfInfo() {
    final self = describeSelf();
    return QuickShareEndpointInfo(name: self.name, kind: self.kind);
  }

  bool get _isComputer =>
      options.onComputer ??
      (Platform.isMacOS || Platform.isLinux || Platform.isWindows);

  void _emit() {
    if (_changes.isClosed) {
      return;
    }

    _changes.add(null);
  }
}
