import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:iphone/models/models.dart';
import 'package:iphone/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart' hide Platform;

/// An iPhone next to a Windows, Linux or Mac computer, with no Ferret on the
/// iPhone: the computer reads the iPhone's notifications and media over the
/// Bluetooth LE services every iPhone offers a paired device.
///
/// It has no Ferret messages of its own, so other Ferret devices never see
/// it as a feature.
class IphoneFeature extends Feature {
  IphoneFeature({
    AppleTransport Function()? transport,
    DateTime Function()? clock,
    bool? isSupported,
    this.connectTimeout = const Duration(seconds: 25),
    this.retryDelays,
  }) : _createTransport = transport ?? AppleTransport.current,
       _clock = clock ?? DateTime.now,
       isSupported =
           isSupported ??
           (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static const featureId = 'iphone';

  /// Whether this platform can be a Bluetooth client of an iPhone. Phones
  /// can't; Ferret phones talk Ferret instead.
  final bool isSupported;

  final Duration connectTimeout;

  /// The waits between attempts to reach the iPhone, or null for the usual.
  final List<Duration>? retryDelays;

  final AppleTransport Function() _createTransport;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast(sync: true);
  final StreamController<FeedEvent> _notifications = .broadcast(sync: true);
  final List<StreamSubscription<Object?>> _subscriptions = [];

  AppleTransport? _transport;
  IphoneLink? _link;
  NotificationFeed? _feed;

  @override
  String get id => featureId;

  @override
  bool get isAvailable => false;

  IphoneSettings get settings => IphoneSettings(host.settings);

  LinkState get link => _link?.state ?? const LinkState(phase: .unsupported);

  /// What the iPhone plays; empty while nothing is loaded or not connected.
  AmsState get media => _link?.ams.state ?? const AmsState();

  /// When the iPhone last sent anything.
  DateTime? get lastActivity => _link?.lastActivity;

  /// Whether this computer shows itself to the iPhone while it waits for it
  /// (Linux), so pairing starts from the iPhone.
  bool get invitesIphone => _transport?.canInvite ?? false;

  /// Fires when the link, the media or a setting changes.
  Stream<void> get changes => _changes.stream;

  /// New, changed and removed notifications. Never the ones that were
  /// already on the iPhone when it connected.
  Stream<FeedEvent> get notifications => _notifications.stream;

  @override
  Future<void> onStart() async {
    if (!isSupported) {
      return;
    }

    final transport = _createTransport();
    final link = IphoneLink(
      transport: transport,
      settings: settings,
      clock: _clock,
      connectTimeout: connectTimeout,
      retryDelays: retryDelays ?? IphoneLink.defaultRetryDelays,
    );
    final feed = NotificationFeed(link.ancs)..start();
    _transport = transport;
    _link = link;
    _feed = feed;
    _subscriptions
      ..add(link.changes.listen((_) => _onLinkChanged()))
      ..add(link.ams.states.listen((_) => _emit()))
      ..add(feed.events.listen(_notifications.add))
      ..add(settings.changes.listen(_onSettingChanged));
    link.start();
  }

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    _subscriptions.clear();
    final link = _link;
    _feed?.dispose();
    _feed = null;
    _link = null;
    _transport = null;
    await link?.dispose();
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;

  /// Looks at Bluetooth again, such as when the app comes back to the front
  /// or the person taps "Try again". A working link is left alone.
  Future<void> refresh({bool force = false}) async {
    await _link?.refresh(force: force);
  }

  /// The devices the person can pick the iPhone from.
  Future<List<BondedDevice>> devices() async =>
      await _link?.devices() ?? const [];

  Future<void> chooseDevice(BondedDevice device) =>
      settings.setDevice(id: device.id, name: device.name);

  Future<void> forgetDevice() => settings.clearDevice();

  /// Tells the iPhone's player to do [command]. False when it didn't get
  /// there.
  Future<bool> sendMedia(AmsCommand command) async {
    final link = _link;
    if (link == null || !link.state.hasMedia) {
      return false;
    }

    return _attempt(() => link.ams.send(command));
  }

  /// Performs a notification's action on the iPhone. False when it didn't
  /// get there.
  Future<bool> perform(int uid, AncsAction action) async {
    final link = _link;
    if (link == null || !link.state.hasNotifications) {
      return false;
    }

    return _attempt(() => link.ancs.perform(uid, action));
  }

  /// Opens the system's Bluetooth settings. False when that failed.
  Future<bool> openBluetoothSettings() async {
    final transport = _transport;
    if (transport == null) {
      return false;
    }

    try {
      await transport.openBluetoothSettings();
      return true;
    } on Object catch (error) {
      printWarning('Opening the Bluetooth settings failed', error);
      return false;
    }
  }

  Future<bool> _attempt(Future<void> Function() command) async {
    try {
      await command();
      return true;
    } on GattException catch (error) {
      printWarning('An iPhone command failed: ${error.failure.name}');
      return false;
    }
  }

  void _onLinkChanged() {
    if (!link.isConnected) {
      _feed?.reset();
    }

    _emit();
  }

  void _onSettingChanged(String key) {
    final reconnects = switch (key) {
      IphoneSettings.enabledKey ||
      IphoneSettings.deviceIdKey ||
      IphoneSettings.showNotificationsKey ||
      IphoneSettings.showMediaKey => true,
      _ => false,
    };
    if (reconnects) {
      unawaited(refresh(force: true));
    }

    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
