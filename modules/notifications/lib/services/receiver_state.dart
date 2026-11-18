/// What a phone remembers about one receiving device, across sessions.
class ReceiverState {
  /// When the current session opened, in the phone's clock, or null while
  /// the receiver is away.
  int? connectedSinceMs;

  /// Keys sent to the receiver and still showing, with their content hash.
  final Map<String, int> forwarded = {};

  /// Keys posted while the receiver was away and still showing, with their
  /// app's name.
  final Map<String, String> missed = {};

  /// Apps whose icon the receiver already got in this session.
  final Set<String> iconsSent = {};

  bool get isConnected => connectedSinceMs != null;

  void connect(int nowMs) {
    connectedSinceMs = nowMs;
    missed.clear();
    iconsSent.clear();
  }

  void disconnect() {
    connectedSinceMs = null;
    iconsSent.clear();
  }

  /// Forgets [key]. Returns true when the receiver had been sent it.
  bool remove(String key) {
    missed.remove(key);
    return forwarded.remove(key) != null;
  }
}
