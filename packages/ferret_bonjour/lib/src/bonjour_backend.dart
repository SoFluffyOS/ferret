/// One DNS-SD service the system's Bonjour found and looked up.
class BonjourService {
  const BonjourService({
    required this.name,
    required this.port,
    required this.txt,
    this.addresses = const [],
  });

  /// The instance name, the part before the service type.
  final String name;
  final int port;
  final Map<String, String> txt;

  /// The addresses the system resolved the service's host to.
  final List<String> addresses;
}

/// What the system's service browser reports.
sealed class BonjourEvent {
  const BonjourEvent();
}

/// A service showed up or changed, already resolved.
class BonjourFound extends BonjourEvent {
  const BonjourFound(this.service);

  final BonjourService service;
}

/// A service went away: it said goodbye or stopped answering.
class BonjourLost extends BonjourEvent {
  const BonjourLost(this.name);

  final String name;
}

/// Browsing or offering stopped working. [denied] when the system refused
/// it, which is what a local network permission that is off looks like.
class BonjourFailed extends BonjourEvent {
  const BonjourFailed({required this.denied, this.detail = ''});

  final bool denied;
  final String detail;
}

/// An offer on the network, until [stop].
abstract interface class BonjourOffer {
  /// Failures after it started, such as the system taking it back.
  Stream<BonjourFailed> get failures;

  Future<void> stop();
}

/// Browsing for one service type, until [stop].
abstract interface class BonjourBrowser {
  Stream<BonjourEvent> get events;

  Future<void> stop();
}

/// The system's Bonjour, or a fake one in tests.
abstract interface class BonjourBackend {
  /// Offers a service. Throws when the system has no Bonjour to use.
  Future<BonjourOffer> offer({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
  });

  /// Starts browsing for [type]. Throws when the system has no Bonjour to
  /// use.
  Future<BonjourBrowser> browse(String type);
}
