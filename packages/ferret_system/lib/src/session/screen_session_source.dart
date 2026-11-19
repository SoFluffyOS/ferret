/// Where [ScreenSession] learns whether the person is at this computer.
abstract interface class ScreenSessionSource {
  /// Whether the screen is unlocked with this account in front right now.
  Future<bool> isActive();

  /// Each change, once [start] ran.
  Stream<bool> get changes;

  Future<void> start();

  Future<void> stop();
}

/// For platforms with no lock or account switch to watch, such as phones.
class AlwaysActiveSource implements ScreenSessionSource {
  const AlwaysActiveSource();

  @override
  Future<bool> isActive() async => true;

  @override
  Stream<bool> get changes => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
