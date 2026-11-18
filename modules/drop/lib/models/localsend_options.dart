import 'dart:io';

/// How Drop speaks LocalSend. The defaults are the protocol's; tests use
/// loopback and no multicast.
class LocalSendOptions {
  const LocalSendOptions({
    this.port = 53317,
    this.bindAddress,
    this.useMulticast = true,
    this.scanAddresses = true,
    this.receiveWindow = const Duration(minutes: 10),
    this.answerTimeout = const Duration(minutes: 2),
    this.multicastWait = const Duration(milliseconds: 1500),
  });

  final int port;

  /// The address the receive server listens on; every IPv4 interface when
  /// null.
  final InternetAddress? bindAddress;

  /// Whether to find devices with multicast.
  final bool useMulticast;

  /// Whether to ask each address on the network when multicast finds
  /// nobody.
  final bool scanAddresses;

  /// How long "Receive from LocalSend" stays on when turned on from the
  /// home card.
  final Duration receiveWindow;

  /// How long an offer waits for someone here to accept it.
  final Duration answerTimeout;

  /// How long multicast gets to find someone before addresses are asked.
  final Duration multicastWait;
}
