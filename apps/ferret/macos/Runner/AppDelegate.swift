import Cocoa
import FlutterMacOS
import ferret_menubar

@main
class AppDelegate: FlutterAppDelegate {
  // A menubar app: closing the popover or the window must not quit.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // A click on the Dock icon opens the window, or brings it to the front.
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    FerretMenubarPlugin.openWindow()
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
