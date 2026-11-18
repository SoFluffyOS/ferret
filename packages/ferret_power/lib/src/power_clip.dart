/// Text read from the clipboard through a power-up tier.
class PowerClip {
  const PowerClip(this.text, {this.sensitive = false});

  final String text;

  /// The source app marked it as private, such as a password manager.
  final bool sensitive;
}
