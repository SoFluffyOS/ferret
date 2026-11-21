import 'package:flutter/widgets.dart';

/// Where iOS asks about the local network the first time Ferret sends
/// something there, Ferret says why first. Features that reach the
/// network on their own, such as receiving from LocalSend, go through
/// [ask] before they start.
abstract interface class LocalNetworkGate implements Listenable {
  /// Whether Ferret still has to say why before it looks for devices.
  bool get needsAsk;

  /// Says why when that is still needed and lets Ferret on the network
  /// once the person goes on. True when Ferret may use the network.
  Future<bool> ask(BuildContext context);
}
