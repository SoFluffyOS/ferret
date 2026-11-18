/// A key held with another key.
enum KeyModifier {
  shift(1),
  control(2),
  alt(4),

  /// Command on macOS, the Windows key on Windows, Super on Linux.
  meta(8);

  const KeyModifier(this.bit);

  /// This modifier's bit in a native event's `modifiers`.
  final int bit;

  static int bitsOf(Iterable<KeyModifier> modifiers) =>
      modifiers.fold(0, (bits, modifier) => bits | modifier.bit);
}
