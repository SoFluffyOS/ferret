/// Where to open a media item on this device: the best link first, then
/// fallbacks, such as the Spotify app and then the Spotify web player.
class ContinueLink {
  const ContinueLink(this.candidates, {required this.keepsPosition});

  final List<Uri> candidates;

  /// Whether the first link starts at the position, not at the beginning.
  final bool keepsPosition;
}
