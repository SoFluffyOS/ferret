import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_iphone/src/transport/transport.dart';

/// An [AppleTransport] in memory: records what was written, and lets a test
/// play the iPhone.
class FakeAppleTransport implements AppleTransport {
  FakeAppleTransport({
    this.statusNow = .ready,
    List<BondedDevice>? bonded,
    this.services = const AppleServices(hasAncs: true, hasAms: true),
    this.canInvite = false,
  }) : bonded = bonded ?? [];

  BluetoothStatus statusNow;
  List<BondedDevice> bonded;

  /// What a connected device offers.
  AppleServices services;

  @override
  bool canInvite;

  /// Thrown by [connect], such as when the iPhone is out of reach.
  GattException? connectError;

  /// Holds [connect] until it completes, such as an iPhone that never
  /// answers.
  Future<void>? connectHold;

  /// Thrown by [setNotify], such as when the iPhone isn't bonded.
  GattException? notifyError;

  /// Thrown by [write].
  GattException? writeError;

  /// Called for every write, to answer it the way an iPhone would.
  FutureOr<void> Function(AppleCharacteristic characteristic, Uint8List value)?
  onWrite;

  /// What [read] returns, by characteristic.
  final Map<AppleCharacteristic, Uint8List> readable = {};

  final List<(AppleCharacteristic, Uint8List)> writes = [];
  final Set<AppleCharacteristic> notifying = {};
  final List<String> connects = [];
  String? connectedTo;
  bool inviting = false;
  int settingsOpened = 0;
  int disconnectCount = 0;
  bool disposed = false;

  final StreamController<GattValue> _values = .broadcast(sync: true);
  final StreamController<String> _disconnects = .broadcast(sync: true);

  /// The iPhone notifies [bytes] on [characteristic], if notify is on.
  void emit(AppleCharacteristic characteristic, List<int> bytes) {
    if (notifying.contains(characteristic)) {
      _values.add(GattValue(characteristic, Uint8List.fromList(bytes)));
    }
  }

  /// The iPhone goes out of reach.
  void drop() {
    final device = connectedTo;
    if (device == null) {
      return;
    }

    connectedTo = null;
    notifying.clear();
    _disconnects.add(device);
  }

  /// Everything written to [characteristic], oldest first.
  List<Uint8List> writesTo(AppleCharacteristic characteristic) => [
    for (final (target, value) in writes)
      if (target == characteristic) value,
  ];

  @override
  Stream<GattValue> get values => _values.stream;

  @override
  Stream<String> get disconnects => _disconnects.stream;

  @override
  Future<BluetoothStatus> status() async => statusNow;

  @override
  Future<List<BondedDevice>> devices() async => bonded;

  @override
  Future<AppleServices> connect(String deviceId) async {
    connects.add(deviceId);
    if (connectHold case final hold?) {
      await hold;
    }

    if (connectError case final error?) {
      throw error;
    }

    connectedTo = deviceId;
    notifying.clear();
    return services;
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
    connectedTo = null;
    notifying.clear();
  }

  @override
  Future<void> write(
    AppleCharacteristic characteristic,
    Uint8List value,
  ) async {
    _requireLink();
    if (writeError case final error?) {
      throw error;
    }

    writes.add((characteristic, value));
    await onWrite?.call(characteristic, value);
  }

  @override
  Future<Uint8List> read(AppleCharacteristic characteristic) async {
    _requireLink();
    return readable[characteristic] ?? Uint8List(0);
  }

  @override
  Future<void> setNotify(
    AppleCharacteristic characteristic, {
    required bool enabled,
  }) async {
    _requireLink();
    if (notifyError case final error?) {
      throw error;
    }

    if (enabled) {
      notifying.add(characteristic);
      return;
    }

    notifying.remove(characteristic);
  }

  @override
  Future<void> setInviting({required bool inviting}) async {
    this.inviting = inviting;
  }

  @override
  Future<void> openBluetoothSettings() async {
    settingsOpened++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void _requireLink() {
    if (connectedTo == null) {
      throw const GattException(.notConnected);
    }
  }
}
