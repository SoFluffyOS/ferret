/// Whether Ferret is paused, and until when.
class PauseState {
  const PauseState({required this.isPaused, this.until});

  static const running = PauseState(isPaused: false);

  final bool isPaused;

  /// When the pause ends by itself, or null for "until I resume".
  final DateTime? until;

  @override
  bool operator ==(Object other) =>
      other is PauseState && other.isPaused == isPaused && other.until == until;

  @override
  int get hashCode => Object.hash(isPaused, until);

  @override
  String toString() => 'PauseState(paused: $isPaused, until: $until)';
}
