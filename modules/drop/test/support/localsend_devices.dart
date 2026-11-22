import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart' show MulticastNeed;

import 'files.dart';

/// LocalSend on loopback: a random port, no multicast, no address sweep.
const loopbackOptions = LocalSendOptions(
  port: 0,
  useMulticast: false,
  scanAddresses: false,
  multicastWait: Duration.zero,
);

/// Quick Share on loopback: no mDNS, and short waits.
final loopbackQuickShare = QuickShareOptions(
  bindAddress: InternetAddress.loopbackIPv4,
  advertise: false,
  timeouts: const QuickShareTimeouts(
    handshake: Duration(seconds: 5),
    idle: Duration(seconds: 5),
    keepAlive: Duration(milliseconds: 200),
    closeGrace: Duration(milliseconds: 200),
  ),
);

/// A device with Drop and no paired devices, for LocalSend and Quick
/// Share tests.
class SoloDevice implements FeatureHost {
  SoloDevice(this.name, this.feature, this.settings, this.secrets);

  /// Starts Drop on a device that saves into [inbox]. Pass [identity] to
  /// skip making a certificate.
  static Future<SoloDevice> start(
    String name,
    Directory inbox, {
    LocalSendOptions options = loopbackOptions,
    QuickShareOptions? quickShare,
    Map<String, Object?> settings = const {},
    LocalSendIdentity? identity,
    MulticastNeed? multicastNeed,
  }) async {
    final secrets = MemorySecretStore();
    if (identity != null) {
      await secrets.write('drop.localsend_identity', identity.encode());
    }

    final device = SoloDevice(
      name,
      DropFeature(
        store: folderStore(inbox),
        secrets: secrets,
        localSendOptions: LocalSendOptions(
          port: options.port,
          bindAddress: InternetAddress.loopbackIPv4,
          useMulticast: options.useMulticast,
          scanAddresses: options.scanAddresses,
          receiveWindow: options.receiveWindow,
          answerTimeout: options.answerTimeout,
          multicastWait: options.multicastWait,
          hearsRegisters: options.hearsRegisters,
        ),
        quickShareOptions: quickShare ?? loopbackQuickShare,
        multicastNeed: multicastNeed,
      ),
      MemorySettingsStore({...settings}),
      secrets,
    );
    await device.feature.start(device);
    return device;
  }

  final String name;
  final DropFeature feature;
  final MemorySecretStore secrets;

  @override
  final SettingsStore settings;

  LocalSendBridge get localSend => feature.localSend;

  QuickShareBridge get quickShare => feature.quickShare;

  List<Transfer> get transfers => feature.transfers;

  @override
  DeviceInfo get localDevice => DeviceInfo(
    id: '$name-id',
    name: name,
    platform: .PLATFORM_MACOS,
    formFactor: .FORM_FACTOR_LAPTOP,
  );

  @override
  List<Session> get sessions => const [];

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Session? sessionFor(String deviceId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
