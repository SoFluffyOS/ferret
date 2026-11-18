/// One way to open an activity. The opener tries the steps of a plan in
/// order and stops at the first that works.
sealed class OpenStep {
  const OpenStep();
}

/// Opens [uri] in the app [appId] (Android package or Apple bundle id).
final class OpenInApp extends OpenStep {
  const OpenInApp(this.uri, this.appId);

  final String uri;
  final String appId;

  @override
  bool operator ==(Object other) =>
      other is OpenInApp && other.uri == uri && other.appId == appId;

  @override
  int get hashCode => Object.hash(uri, appId);

  @override
  String toString() => 'OpenInApp($uri, $appId)';
}

/// Opens [uri] with whatever handles it. With [appsOnly], a browser doesn't
/// count, so an app link falls through to the next step when no app has it.
final class OpenLink extends OpenStep {
  const OpenLink(this.uri, {this.appsOnly = false});

  final String uri;
  final bool appsOnly;

  @override
  bool operator ==(Object other) =>
      other is OpenLink && other.uri == uri && other.appsOnly == appsOnly;

  @override
  int get hashCode => Object.hash(uri, appsOnly);

  @override
  String toString() => 'OpenLink($uri, appsOnly: $appsOnly)';
}

/// Puts [text] on the clipboard, for text activities.
final class CopyText extends OpenStep {
  const CopyText(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is CopyText && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'CopyText(${text.length} chars)';
}
