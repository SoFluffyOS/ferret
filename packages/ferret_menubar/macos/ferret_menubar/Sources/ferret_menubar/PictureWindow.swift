import Cocoa

/// How Command-0, Command-plus and Command-minus size the picture window.
enum PictureWindowStep {
    /// One pixel of the picture per pixel of the screen.
    case actual
    case larger
    case smaller
}

/// A window that is its picture and nothing else. Command-W closes it, and
/// the size keys stay with the window instead of reaching Flutter.
final class PictureWindow: NSWindow {
    var onStep: ((PictureWindowStep) -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function, .capsLock])
        // Plus is Shift and = on most keyboards, and its own key on others.
        guard modifiers == .command || modifiers == [.command, .shift] else {
            return super.performKeyEquivalent(with: event)
        }

        switch (event.charactersIgnoringModifiers, modifiers.contains(.shift)) {
        case ("w", false):
            performClose(nil)
        case ("0", false):
            onStep?(.actual)
        case ("=", _), ("+", _):
            onStep?(.larger)
        case ("-", false):
            onStep?(.smaller)
        default:
            return super.performKeyEquivalent(with: event)
        }

        return true
    }
}
