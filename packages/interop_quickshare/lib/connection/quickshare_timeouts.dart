/// How patient a Quick Share connection is. Tests shorten these.
class QuickShareTimeouts {
  const QuickShareTimeouts({
    this.handshake = const Duration(seconds: 15),
    this.idle = const Duration(seconds: 60),
    this.keepAlive = const Duration(seconds: 10),
    this.closeGrace = const Duration(seconds: 3),
  });

  /// How long each step of opening a connection may take.
  final Duration handshake;

  /// How long the other side may stay silent once the connection is
  /// open. Phones send a keep-alive every 10 seconds.
  final Duration idle;

  /// How often this side says it is still there.
  final Duration keepAlive;

  /// How long the other side gets to hang up before this side does.
  final Duration closeGrace;
}
