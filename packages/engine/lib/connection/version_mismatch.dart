import 'package:protocol/protocol.dart';

/// Which of two devices has to update Ferret before they can talk.
enum UpdateNeeded { thisDevice, otherDevice }

/// Two paired devices whose Ferret versions no longer speak the same
/// protocol. Both work it out from the two `Hello`s alone, so each can say
/// which one to update instead of failing silently.
class VersionMismatch {
  const VersionMismatch({
    required this.update,
    required this.remoteProtocol,
    this.remoteAppVersion = '',
  });

  final UpdateNeeded update;

  /// The newest protocol version the other device speaks.
  final int remoteProtocol;

  /// The other device's Ferret version, such as "0.1.0", when it said.
  final String remoteAppVersion;

  /// The mismatch between [local] and [remote], or null when their protocol
  /// ranges overlap.
  static VersionMismatch? between(DeviceInfo local, DeviceInfo remote) {
    final (localOldest, localNewest) = _range(local);
    final (remoteOldest, remoteNewest) = _range(remote);

    final update = switch ((
      remoteNewest < localOldest,
      localNewest < remoteOldest,
    )) {
      (true, _) => UpdateNeeded.otherDevice,
      (_, true) => UpdateNeeded.thisDevice,
      _ => null,
    };
    if (update == null) {
      return null;
    }

    return VersionMismatch(
      update: update,
      remoteProtocol: remoteNewest,
      remoteAppVersion: remote.appVersion,
    );
  }

  /// Apps from before `oldest_protocol_version` send zero for it, and the
  /// very first builds zero for both: they speak version 1 only.
  static (int, int) _range(DeviceInfo info) {
    final newest = switch (info.protocolVersion) {
      0 => 1,
      final version => version,
    };
    final oldest = switch (info.oldestProtocolVersion) {
      0 => newest,
      final version when version > newest => newest,
      final version => version,
    };

    return (oldest, newest);
  }
}
