import 'dart:io';

import 'package:interop_quickshare/interop_quickshare.dart';

/// How Drop speaks Quick Share. The defaults are for real networks; tests
/// use loopback and no mDNS.
class QuickShareOptions {
  const QuickShareOptions({
    this.port = 0,
    this.bindAddress,
    this.advertise = true,
    this.receiveWindow = const Duration(minutes: 10),
    this.answerTimeout = const Duration(minutes: 2),
    this.timeouts = const QuickShareTimeouts(),
  });

  /// The port phones connect to. Quick Share has no fixed one, so any
  /// free port is taken by default.
  final int port;

  /// The address the receive server listens on; every IPv4 interface when
  /// null.
  final InternetAddress? bindAddress;

  /// Whether to announce this device over mDNS while it is visible.
  final bool advertise;

  /// How long this device stays visible when turned on from the home
  /// card.
  final Duration receiveWindow;

  /// How long an offer waits for someone here to accept it.
  final Duration answerTimeout;
  final QuickShareTimeouts timeouts;
}
