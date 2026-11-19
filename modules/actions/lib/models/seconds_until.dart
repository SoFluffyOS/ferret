/// Whole seconds from [now] until [endsAt], rounded up and never below
/// zero, for a countdown on screen.
int secondsUntil(DateTime endsAt, DateTime now) {
  final left = endsAt.difference(now);
  if (left <= Duration.zero) {
    return 0;
  }

  return (left.inMilliseconds / Duration.millisecondsPerSecond).ceil();
}
