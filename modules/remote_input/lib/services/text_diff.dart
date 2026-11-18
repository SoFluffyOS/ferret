/// What changed between two versions of the keyboard field: how many
/// characters were deleted at the end, and what was typed after.
typedef TextChange = ({int deleted, String inserted});

abstract final class TextDiff {
  /// The change from [before] to [after], sharing their longest common
  /// start. A field edited in the middle reads as deleting back to the edit
  /// and typing the rest again, which is what Backspace and typing do.
  static TextChange between(String before, String after) {
    final beforeRunes = before.runes.toList();
    final afterRunes = after.runes.toList();
    var common = 0;
    while (common < beforeRunes.length &&
        common < afterRunes.length &&
        beforeRunes[common] == afterRunes[common]) {
      common++;
    }

    return (
      deleted: beforeRunes.length - common,
      inserted: String.fromCharCodes(afterRunes.skip(common)),
    );
  }
}
