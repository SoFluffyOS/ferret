/// Handoff's settings keys and their defaults.
abstract final class HandoffSettings {
  /// Share what you're doing as quiet suggestions, and show others'.
  static const passive = 'handoff.passive';

  /// Open explicit "Continue on…" sends right away instead of as a notice.
  static const openAutomatically = 'handoff.open_automatically';

  /// macOS: read the current browser page (needs Automation permission).
  static const browserTab = 'handoff.browser_tab';

  /// Desktop: let paired browser extensions talk to Ferret on this computer.
  static const browserBridge = 'handoff.browser_bridge';

  /// The browser extensions the user allowed, with their token hashes.
  static const browserClients = 'handoff.browser_clients';

  /// The recent activities, newest first.
  static const timeline = 'handoff.timeline';

  static const passiveDefault = true;
  static const openAutomaticallyDefault = true;
  static const browserTabDefault = false;
  static const browserBridgeDefault = true;
}
