import 'package:handoff/models/send_outcome.dart';

/// What happened when sending the browser's current page.
sealed class CurrentPageResult {
  const CurrentPageResult();
}

final class PageSent extends CurrentPageResult {
  const PageSent(this.outcome);

  final SendOutcome outcome;
}

/// No supported browser shows a page.
final class PageMissing extends CurrentPageResult {
  const PageMissing();
}

/// macOS Automation permission was refused.
final class PageDenied extends CurrentPageResult {
  const PageDenied();
}

final class PageUnreadable extends CurrentPageResult {
  const PageUnreadable();
}
