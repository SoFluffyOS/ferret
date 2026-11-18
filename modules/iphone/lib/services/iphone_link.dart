import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:iphone/models/models.dart';

/// Keeps the Bluetooth link to the chosen iPhone: connects when the feature
/// is on, subscribes to notifications and media, and comes back by itself
/// after the iPhone was away, the computer slept or Bluetooth was off.
class IphoneLink {
  IphoneLink({
    required AppleTransport transport,
    required IphoneSettings settings,
    DateTime Function()? clock,
    this.connectTimeout = const Duration(seconds: 25),
    this.retryDelays = defaultRetryDelays,
  }) : _transport = transport,
       _settings = settings,
       _clock = clock ?? DateTime.now,
       ancs = AncsClient(transport),
       ams = AmsClient(transport, clock: clock);

  static const defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];

  /// How long one attempt to reach the iPhone may take.
  final Duration connectTimeout;

  /// The waits between attempts; the last one repeats.
  final List<Duration> retryDelays;

  final AncsClient ancs;
  final AmsClient ams;

  final AppleTransport _transport;
  final IphoneSettings _settings;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast(sync: true);
  final List<StreamSubscription<Object?>> _subscriptions = [];

  LinkState _state = const LinkState();
  Timer? _retry;
  int _failures = 0;
  DateTime? _lastActivity;

  /// Counts attempts, so an older one that is still waiting on the iPhone
  /// can tell it was replaced.
  int _attempt = 0;
  bool _disposed = false;

  LinkState get state => _state;

  /// When the iPhone last sent anything: the link's real pulse.
  DateTime? get lastActivity => _lastActivity;

  /// Fires when [state] changes.
  Stream<void> get changes => _changes.stream;

  /// Starts watching the link and makes the first attempt, without waiting
  /// for the iPhone.
  void start() {
    _subscriptions
      ..add(_transport.disconnects.listen((_) => _onDropped()))
      ..add(_transport.values.listen((_) => _lastActivity = _clock()));
    unawaited(refresh(force: true));
  }

  /// Looks at the settings and Bluetooth again and connects if it should.
  /// A working link is left alone unless [force] is set, such as after a
  /// setting changed.
  Future<void> refresh({bool force = false}) async {
    if (_disposed || (_state.isConnected && !force)) {
      return;
    }

    if (_state.phase == .connecting && !force) {
      return;
    }

    final attempt = ++_attempt;
    _retry?.cancel();
    _retry = null;
    await _closeLink();
    if (_isStale(attempt)) {
      return;
    }

    if (!_settings.enabled) {
      await _invite(false);
      _set(const LinkState());
      return;
    }

    final blocked = await _blockedBy();
    if (_isStale(attempt)) {
      return;
    }

    if (blocked != null) {
      await _invite(false);
      _set(LinkState(phase: blocked, deviceName: _settings.deviceName));
      _retryIf(blocked == .bluetoothOff || blocked == .failed);
      return;
    }

    await _invite(true);
    final deviceId = _settings.deviceId;
    if (deviceId == null) {
      _set(const LinkState(phase: .noDevice));
      return;
    }

    _set(LinkState(phase: .connecting, deviceName: _settings.deviceName));
    final LinkState reached;
    try {
      reached = await _connect(deviceId).timeout(
        connectTimeout,
        onTimeout: () => throw const GattException(.timeout),
      );
    } on GattException catch (error) {
      if (_isStale(attempt)) {
        return;
      }

      await _closeLink();
      _set(LinkState(phase: _phaseOf(error), deviceName: _settings.deviceName));
      _retryIf(true);
      return;
    }

    if (_isStale(attempt)) {
      return;
    }

    _set(reached);
    if (!reached.isConnected) {
      await _closeLink();
      _retryIf(true);
      return;
    }

    _failures = 0;
    _lastActivity = _clock();
    await _invite(false);
  }

  /// The devices that could be the iPhone, as the system lists them.
  Future<List<BondedDevice>> devices() async {
    try {
      return await _transport.devices();
    } on GattException {
      return const [];
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _attempt++;
    _retry?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    _subscriptions.clear();
    ancs.dispose();
    ams.dispose();
    unawaited(_changes.close());
    await _invite(false);
    try {
      await _transport.disconnect();
    } on GattException {
      // Nothing to close.
    }

    await _transport.dispose();
  }

  bool _isStale(int attempt) => _disposed || attempt != _attempt;

  Future<LinkPhase?> _blockedBy() async {
    final BluetoothStatus status;
    try {
      status = await _transport.status();
    } on GattException {
      return .failed;
    }

    return switch (status) {
      .ready => null,
      .off => .bluetoothOff,
      .unauthorized => .unauthorized,
      .unsupported => .unsupported,
      .notConfigured => .notConfigured,
    };
  }

  Future<LinkState> _connect(String deviceId) async {
    final services = await _transport.connect(deviceId);
    final wantsNotifications = _settings.showNotifications;
    final wantsMedia = _settings.showMedia;
    if (services.isEmpty) {
      return LinkState(phase: .notShared, deviceName: _settings.deviceName);
    }

    final hasNotifications = services.hasAncs && wantsNotifications;
    final hasMedia = services.hasAms && wantsMedia;
    if (hasNotifications) {
      await ancs.start();
    }

    if (hasMedia) {
      await ams.start();
    }

    return LinkState(
      phase: .connected,
      deviceName: _settings.deviceName,
      hasNotifications: hasNotifications,
      hasMedia: hasMedia,
      connectedAt: _clock(),
    );
  }

  LinkPhase _phaseOf(GattException error) => switch (error.failure) {
    .notBonded => .notShared,
    .notConnected || .timeout => .outOfReach,
    .missing || .att || .failed => .failed,
  };

  void _onDropped() {
    if (_disposed || !_settings.enabled) {
      return;
    }

    if (_state.phase != .connected) {
      return;
    }

    _attempt++;
    _set(LinkState(phase: .outOfReach, deviceName: _settings.deviceName));
    unawaited(_afterDrop());
  }

  Future<void> _afterDrop() async {
    await _closeLink();
    await _invite(true);
    _retryIf(true);
  }

  Future<void> _closeLink() async {
    ancs.stop();
    ams.stop();
    try {
      await _transport.disconnect();
    } on GattException {
      // Already gone.
    }
  }

  /// On Linux the computer shows itself to the iPhone while it waits for
  /// it, which is what makes the iPhone come back on its own.
  Future<void> _invite(bool inviting) async {
    if (!_transport.canInvite) {
      return;
    }

    try {
      await _transport.setInviting(inviting: inviting);
    } on Object catch (error) {
      printWarning('Inviting the iPhone failed: ${error.runtimeType}');
    }
  }

  void _retryIf(bool retry) {
    if (!retry || _disposed || retryDelays.isEmpty) {
      return;
    }

    final index = _failures.clamp(0, retryDelays.length - 1);
    _failures++;
    _retry?.cancel();
    _retry = Timer(retryDelays[index], () => unawaited(refresh(force: true)));
  }

  void _set(LinkState state) {
    if (state == _state || _changes.isClosed) {
      return;
    }

    _state = state;
    _changes.add(null);
  }
}
