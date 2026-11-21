import 'package:engine/group/device_joined.dart';
import 'package:engine/identity/identity.dart';
import 'package:engine/pairing/pairing.dart';
import 'package:engine/trust/trust.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/protocol.dart' hide ForgottenDevice;
import 'package:protocol/protocol.dart' as proto show ForgottenDevice;

/// What applying an `Introduce` changed here.
typedef RosterChanges = ({List<DeviceJoined> joined, List<String> removed});

/// A trusted device another one removed everywhere, with when.
typedef RosterRemoval = ({TrustedDevice device, DateTime at});

/// What an `Introduce` would change here, before anything is trusted or
/// dropped.
typedef RosterProposal = ({
  List<DeviceJoined> joins,
  List<RosterRemoval> removals,
});

/// Keeps the user's devices the same everywhere: tells a paired device
/// which others this one trusts, and takes in what it tells.
///
/// The rule is that every paired device belongs to the same person, so a
/// device one of them vouches for is trusted here too. That makes each
/// paired device able to propose devices everywhere, which is why it only
/// happens over a session with a device already trusted, never with a
/// stranger, why the user can turn it off, and why the engine asks the
/// user before it takes a proposal in (see [review]).
///
/// Removing follows the same road. A device forgotten "everywhere" is
/// passed on with the time it was forgotten; whoever still trusts an older
/// pairing of it drops it. A device forgotten only here stays forgotten
/// here and is not passed on. Pairing a device again by hand always wins,
/// because that pairing is newer than the forgetting.
class DeviceRoster {
  DeviceRoster(this._trustStore, this._localDeviceId, {this.beforeJoin});

  static const maxDevices = 64;
  static const _keyLength = 32;

  final TrustStore _trustStore;
  final String _localDeviceId;

  /// Runs before a device another one vouched for is trusted here, so what
  /// it may use is settled before it can connect.
  final Future<void> Function(String deviceId, TrustedDevice introducer)?
  beforeJoin;

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

  /// Takes in what the trusted device [introducer] says, all of it at
  /// once. Forgetting goes first, so a device removed and listed at once
  /// stays removed.
  Future<RosterChanges> apply(
    Introduce introduce,
    TrustedDevice introducer,
  ) async {
    final proposal = await review(introduce, introducer);
    final removed = <String>[];
    for (final removal in proposal.removals) {
      if (await remove(removal)) {
        removed.add(removal.device.id);
      }
    }

    final joined = <DeviceJoined>[];
    for (final join in proposal.joins) {
      if (await this.join(join)) {
        joined.add(join);
      }
    }

    return (joined: joined, removed: removed);
  }

  /// What [introducer] proposes, checked: devices whose key matches their
  /// id and that aren't trusted or forgotten here, and trusted devices it
  /// removed after they were paired. Forgetting a device that isn't
  /// trusted here changes nothing the user can see, so that is kept right
  /// away: it stops an older word about the device from bringing it in.
  Future<RosterProposal> review(
    Introduce introduce,
    TrustedDevice introducer,
  ) async {
    final removals = <RosterRemoval>[];
    for (final forgotten in introduce.forgotten.take(maxDevices)) {
      if (forgotten.id == _localDeviceId ||
          forgotten.id == introducer.id ||
          forgotten.id.isEmpty) {
        continue;
      }

      final at = DateTime.fromMillisecondsSinceEpoch(
        forgotten.forgottenAtMs.toInt(),
      );
      final trusted = _trustStore[forgotten.id];
      if (trusted != null && !trusted.pairedAt.isAfter(at)) {
        removals.add((device: trusted, at: at));
        continue;
      }

      await _trustStore.forget(.new(id: forgotten.id, at: at, by: .everywhere));
    }

    final removing = {for (final removal in removals) removal.device.id};
    final joins = <DeviceJoined>[];
    for (final introduced in introduce.devices.take(maxDevices)) {
      if (removing.contains(introduced.id)) {
        continue;
      }

      final device = await _candidate(introduced, introducer);
      if (device != null) {
        joins.add(DeviceJoined(device: device, introducer: introducer));
      }
    }

    return (joins: joins, removals: removals);
  }

  /// Trusts a device [review] proposed. False when that no longer fits,
  /// such as when it was paired or removed meanwhile.
  Future<bool> join(DeviceJoined joined) async {
    final device = joined.device;
    final forgotten = _trustStore.forgottenOf(device.id);
    if (_trustStore.isTrusted(device.id) ||
        (forgotten != null && !device.pairedAt.isAfter(forgotten.at))) {
      return false;
    }

    await beforeJoin?.call(device.id, joined.introducer);
    await _trustStore.save(device);
    return true;
  }

  /// Drops a device [review] proposed to remove, and remembers it was
  /// removed everywhere. False when it was paired again since.
  Future<bool> remove(RosterRemoval removal) async {
    final id = removal.device.id;
    await _trustStore.forget(.new(id: id, at: removal.at, by: .everywhere));
    final trusted = _trustStore[id];
    if (trusted == null || trusted.pairedAt.isAfter(removal.at)) {
      return false;
    }

    await _trustStore.remove(id);
    return true;
  }

  Future<TrustedDevice?> _candidate(
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

    return TrustedDevice(
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
  }
}
