import 'dart:io';

import 'package:lan_discovery/lan_discovery.dart';

/// How Drop speaks LocalSend. The defaults are the protocol's; tests use
/// loopback and no multicast.
class LocalSendOptions {
  const LocalSendOptions({
    this.port = 53317,
    this.bindAddress,
    bool? useMulticast,
    bool? pausesInBackground,
    this.scanAddresses = true,
    this.receiveWindow = const Duration(minutes: 10),
    this.answerTimeout = const Duration(minutes: 2),
    this.multicastWait = const Duration(milliseconds: 1500),
    this.hearsRegisters = false,
  }) : _useMulticast = useMulticast,
       _pausesInBackground = pausesInBackground;

  final int port;

  /// The address the receive server listens on; every IPv4 interface when
  /// null.
  final InternetAddress? bindAddress;

  /// Whether to find devices with multicast. Left out, wherever the app
  /// may: not on an iPhone until Apple grants the multicast entitlement
  /// ([MulticastEntitlement.iosGranted]). Without it, LocalSend devices
  /// find this one by asking each address, which the receive server
  /// answers, and it finds them the same way.
  bool get useMulticast => _useMulticast ?? MulticastEntitlement.allowed;
  final bool? _useMulticast;

  /// Whether receiving stops while Ferret is in the background and comes
  /// back when it is in front again. Left out, only on an iPhone, where
  /// iOS stops Ferret in the background anyway.
  bool get pausesInBackground => _pausesInBackground ?? Platform.isIOS;
  final bool? _pausesInBackground;

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

  /// Whether a scan listens for `/register` calls even without multicast,
  /// for tests on loopback. With multicast it always does.
  final bool hearsRegisters;
}
