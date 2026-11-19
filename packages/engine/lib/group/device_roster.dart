import 'package:engine/group/device_joined.dart';
import 'package:engine/identity/identity.dart';
import 'package:engine/pairing/pairing.dart';
import 'package:engine/trust/trust.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/protocol.dart' hide ForgottenDevice;
import 'package:protocol/protocol.dart' as proto show ForgottenDevice;

/// What applying an `Introduce` changed here.
typedef RosterChanges = ({List<DeviceJoined> joined, List<String> removed});

/// Keeps the user's devices the same everywhere: tells a paired device
/// which others this one trusts, and takes in what it tells.
///
/// The rule is that every paired device belongs to the same person, so a
/// device one of them vouches for is trusted here too. That makes each
/// paired device able to add devices everywhere, which is why it only
/// happens over a session with a device already trusted, never with a
/// stranger, and why the user can turn it off.
///
/// Removing follows the same road. A device forgotten "everywhere" is
/// passed on with the time it was forgotten; whoever still trusts an older
/// pairing of it drops it. A device forgotten only here stays forgotten
/// here and is not passed on. Pairing a device again by hand always wins,
/// because that pairing is newer than the forgetting.
class DeviceRoster {
  DeviceRoster(this._trustStore, this._localDeviceId);

  static const maxDevices = 64;
  static const _keyLength = 32;

  final TrustStore _trustStore;
  final String _localDeviceId;

  /// What to tell [recipientId]: every other trusted device, and the
  /// devices removed everywhere.
  Introduce introductionFor(String recipientId) => Introduce(
    devices: [
      for (final device in _trustStore.devices)
        if (device.id != recipientId)
          IntroducedDevice(
            id: device.id,
            name: device.ownName,
            platform: device.platform,
            formFactor: device.formFactor,
            staticPublicKey: device.publicKey,
            host: device.lastHost,
            port: device.lastPort,
            pairedAtMs: Int64(device.pairedAt.millisecondsSinceEpoch),
          ),
    ],
    forgotten: [
      for (final device in _trustStore.forgotten)
        if (device.by == .everywhere)
          proto.ForgottenDevice(
            id: device.id,
            forgottenAtMs: Int64(device.at.millisecondsSinceEpoch),
          ),
    ],
  );

  /// The names [introductionFor] would carry, for a pairing prompt.
  List<String> get names => [
    for (final device in _trustStore.devices) device.ownName,
  ];

  /// Takes in what the trusted device [introducer] says. Forgetting goes
  /// first, so a device removed and listed at once stays removed.
  Future<RosterChanges> apply(
    Introduce introduce,
    TrustedDevice introducer,
  ) async {
    final removed = <String>[];
    for (final forgotten in introduce.forgotten.take(maxDevices)) {
      if (await _forget(forgotten, introducer.id)) {
        removed.add(forgotten.id);
      }
    }

    final joined = <DeviceJoined>[];
    for (final introduced in introduce.devices.take(maxDevices)) {
      final device = await _join(introduced, introducer);
      if (device != null) {
        joined.add(DeviceJoined(device: device, introducer: introducer));
      }
    }

    return (joined: joined, removed: removed);
  }

  /// Returns whether a trusted device was dropped.
  Future<bool> _forget(
    proto.ForgottenDevice forgotten,
    String introducerId,
  ) async {
    if (forgotten.id == _localDeviceId ||
        forgotten.id == introducerId ||
        forgotten.id.isEmpty) {
      return false;
    }

    final at = DateTime.fromMillisecondsSinceEpoch(
      forgotten.forgottenAtMs.toInt(),
    );
    await _trustStore.forget(
      .new(id: forgotten.id, at: at, by: .everywhere),
    );

    final trusted = _trustStore[forgotten.id];
    if (trusted == null || trusted.pairedAt.isAfter(at)) {
      return false;
    }

    await _trustStore.remove(forgotten.id);
    return true;
  }

  Future<TrustedDevice?> _join(
    IntroducedDevice introduced,
    TrustedDevice introducer,
  ) async {
    if (introduced.id == _localDeviceId ||
        introduced.id == introducer.id ||
        introduced.staticPublicKey.length != _keyLength ||
        _trustStore.isTrusted(introduced.id)) {
      return null;
    }

    final derivedId = await DeviceIdentity.deviceIdFor(
      introduced.staticPublicKey,
    );
    if (!PairingCodes.same(derivedId.codeUnits, introduced.id.codeUnits)) {
      return null;
    }

    final pairedAt = DateTime.fromMillisecondsSinceEpoch(
      introduced.pairedAtMs.toInt(),
    );
    final forgotten = _trustStore.forgottenOf(introduced.id);
    if (forgotten != null && !pairedAt.isAfter(forgotten.at)) {
      return null;
    }

    final device = TrustedDevice(
      id: introduced.id,
      name: introduced.name,
      platform: introduced.platform,
      formFactor: introduced.formFactor,
      publicKey: .fromList(introduced.staticPublicKey),
      pairedAt: pairedAt,
      lastHost: switch (introduced.host.isEmpty) {
        true => null,
        false => introduced.host,
      },
      lastPort: switch (introduced.port) {
        0 => null,
        final port => port,
      },
      introducedBy: introducer.id,
    );
    await _trustStore.save(device);
    return device;
  }
}
