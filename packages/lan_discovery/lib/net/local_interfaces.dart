import 'dart:io';
import 'dart:typed_data';

/// The addresses this device has on its local networks.
abstract final class LocalInterfaces {
  /// Every IPv4 address a neighbour could reach this device at: one per
  /// network interface, without loopback and link-local ones. Empty when
  /// the system won't list its interfaces.
  static Future<List<InternetAddress>> addresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return [
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback && !address.isLinkLocal) address,
      ];
    } on Object {
      return const [];
    }
  }

  /// The broadcast address of [local]'s network, taken as a /24: Dart
  /// doesn't give an interface's netmask, and home networks are nearly
  /// always /24. Null for anything but IPv4.
  static InternetAddress? subnetBroadcast(InternetAddress local) {
    if (local.type != InternetAddressType.IPv4) {
      return null;
    }

    final bytes = local.rawAddress;
    return InternetAddress.fromRawAddress(
      Uint8List.fromList([bytes[0], bytes[1], bytes[2], 255]),
    );
  }

  /// Joins [group] on every interface of [socket], so packets arrive from
  /// each network and not only the default one. Returns false when no
  /// interface, nor the default, would join.
  static Future<bool> joinEverywhere(
    RawDatagramSocket socket,
    InternetAddress group,
  ) async {
    var joined = false;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        try {
          socket.joinMulticast(group, interface);
          joined = true;
        } on Object {
          continue;
        }
      }
    } on Object {
      joined = false;
    }

    if (joined) {
      return true;
    }

    try {
      socket.joinMulticast(group);
      return true;
    } on Object {
      return false;
    }
  }

  /// Makes [socket] send its next multicast packets from [local]'s
  /// interface, so multicast works without a default route (a VPN, or
  /// several networks at once). Returns false when the system refuses.
  static bool sendMulticastFrom(
    RawDatagramSocket socket,
    InternetAddress local,
  ) {
    try {
      socket.setRawOption(
        RawSocketOption(
          RawSocketOption.levelIPv4,
          RawSocketOption.IPv4MulticastInterface,
          local.rawAddress,
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }
}
