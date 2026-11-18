import Cocoa

/// The desktop window. Command-W closes it, which the app's menu has no
/// item for.
final class AppWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers == .command, event.charactersIgnoringModifiers == "w" else {
            return super.performKeyEquivalent(with: event)
        }

        performClose(nil)
        return true
    }
}
