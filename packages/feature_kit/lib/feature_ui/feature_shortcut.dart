/// Keys a feature answers to from any app, such as ⌃⌥→ to send the
/// keyboard and mouse to the next computer. The shell lists them on the
/// Keyboard shortcuts page.
class FeatureShortcut {
  const FeatureShortcut({required this.keys, required this.label});

  /// Written the way this computer writes them, such as "⌃⌥→".
  final String keys;

  /// What they do, such as "Keyboard and mouse to the next computer".
  final String label;
}
