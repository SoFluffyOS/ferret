import Cocoa
import CoreServices

/// Reads the page shown in Safari or a Chromium browser with AppleScript.
/// macOS asks the user once per browser (Automation permission).
final class BrowserReader {
  private enum Family {
    case safari
    case chromium
  }

  private static let supported: [String: Family] = [
    "com.apple.Safari": .safari,
    "com.apple.SafariTechnologyPreview": .safari,
    "com.google.Chrome": .chromium,
    "com.google.Chrome.beta": .chromium,
    "com.google.Chrome.dev": .chromium,
    "com.google.Chrome.canary": .chromium,
    "org.chromium.Chromium": .chromium,
    "com.brave.Browser": .chromium,
    "com.microsoft.edgemac": .chromium,
    "com.vivaldi.Vivaldi": .chromium,
    "com.operasoftware.Opera": .chromium,
    "company.thebrowser.Browser": .chromium,
  ]

  private let queue = DispatchQueue(label: "io.sofluffy.ferret_handoff.browser")
  private var lastBrowser: String?

  static func isSupported(_ bundleId: String) -> Bool {
    supported[bundleId] != nil
  }

  func noteActivated(_ bundleId: String?) {
    guard let bundleId, Self.isSupported(bundleId) else {
      return
    }

    lastBrowser = bundleId
  }

  /// Answers on the main queue. AEDeterminePermissionToAutomateTarget can
  /// block for a long time even without asking, so it runs on [queue], and
  /// an answer that takes over two seconds counts as not decided yet.
  func access(_ completion: @escaping (BrowserAccess) -> Void) {
    guard let browser = pickBrowser() else {
      completion(.noBrowser)
      return
    }

    var answered = false
    let answer: (BrowserAccess) -> Void = { access in
      DispatchQueue.main.async {
        guard !answered else { return }
        answered = true
        completion(access)
      }
    }

    queue.async { answer(Self.permission(for: browser.bundleId, ask: false)) }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { answer(.notDetermined) }
  }

  func currentTab() async throws -> BrowserTab? {
    guard let browser = pickBrowser() else {
      return nil
    }

    let source = Self.script(for: browser.bundleId)
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
          let code = (error[NSAppleScript.errorNumber] as? Int) ?? 0
          let message = (error[NSAppleScript.errorMessage] as? String) ?? "AppleScript failed"
          continuation.resume(
            throwing: PigeonError(code: Self.errorCode(code), message: message, details: nil))
          return
        }

        guard let result, result.numberOfItems >= 2,
          let url = result.atIndex(1)?.stringValue, !url.isEmpty
        else {
          continuation.resume(returning: nil)
          return
        }

        continuation.resume(
          returning: BrowserTab(
            url: url,
            title: result.atIndex(2)?.stringValue ?? "",
            browserBundleId: browser.bundleId,
            browserName: browser.name))
      }
    }
  }

  private func pickBrowser() -> (bundleId: String, name: String)? {
    let running = NSWorkspace.shared.runningApplications.filter {
      guard let id = $0.bundleIdentifier else {
        return false
      }

      return Self.isSupported(id)
    }

    if let front = NSWorkspace.shared.frontmostApplication,
      let id = front.bundleIdentifier, Self.isSupported(id)
    {
      return (id, front.localizedName ?? id)
    }

    if let lastBrowser,
      let app = running.first(where: { $0.bundleIdentifier == lastBrowser })
    {
      return (lastBrowser, app.localizedName ?? lastBrowser)
    }

    guard let app = running.first, let id = app.bundleIdentifier else {
      return nil
    }

    return (id, app.localizedName ?? id)
  }

  private static func script(for bundleId: String) -> String {
    switch supported[bundleId] {
    case .safari:
      return """
        tell application id "\(bundleId)"
          if (count of windows) is 0 then return {}
          return {URL of current tab of front window, name of current tab of front window}
        end tell
        """
    default:
      return """
        tell application id "\(bundleId)"
          if (count of windows) is 0 then return {}
          return {URL of active tab of front window, title of active tab of front window}
        end tell
        """
    }
  }

  private static func permission(for bundleId: String, ask: Bool) -> BrowserAccess {
    var target = AEAddressDesc()
    let created = bundleId.withCString { pointer in
      AECreateDesc(typeApplicationBundleID, pointer, Int(strlen(pointer)), &target)
    }
    guard created == OSErr(noErr) else {
      return .unsupported
    }

    defer { AEDisposeDesc(&target) }

    let status = AEDeterminePermissionToAutomateTarget(&target, typeWildCard, typeWildCard, ask)
    switch status {
    case OSStatus(noErr):
      return .granted
    case OSStatus(errAEEventWouldRequireUserConsent):
      return .notDetermined
    case OSStatus(procNotFound):
      return .noBrowser
    default:
      return .denied
    }
  }

  private static func errorCode(_ appleScriptError: Int) -> String {
    switch appleScriptError {
    case -1743:
      return "denied"
    case -600:
      return "no-browser"
    default:
      return "script-failed"
    }
  }
}
