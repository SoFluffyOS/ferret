import Carbon.HIToolbox
import Cocoa

/// Catches the next key with a modifier pressed in the app, before Flutter
/// sees it, to make it the global shortcut. Esc alone cancels.
final class ShortcutRecorder {
    private var monitor: Any?
    private var completion: ((MenubarShortcut?) -> Void)?

    /// F1 to F20 work without a modifier: nothing types with them.
    private static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
        kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13", kVK_F14: "F14",
        kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18",
        kVK_F19: "F19", kVK_F20: "F20",
    ]

    private static let namedKeys: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦", kVK_LeftArrow: "←", kVK_RightArrow: "→",
        kVK_UpArrow: "↑", kVK_DownArrow: "↓", kVK_Home: "↖", kVK_End: "↘",
        kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    ]

    var isRecording: Bool { completion != nil }

    func record(_ completion: @escaping (MenubarShortcut?) -> Void) {
        finish(nil)
        self.completion = completion
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            self.take(event)
            return nil
        }
    }

    func cancel() {
        finish(nil)
    }

    private func take(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
        let keyCode = Int(event.keyCode)
        if keyCode == kVK_Escape, flags.isEmpty {
            finish(nil)
            return
        }

        let isFunctionKey = Self.functionKeys[keyCode] != nil
        guard isFunctionKey || !flags.intersection([.command, .control, .option]).isEmpty else {
            NSSound.beep()
            return
        }

        finish(MenubarShortcut(
            keyCode: Int64(keyCode),
            label: Self.label(flags: flags, keyCode: keyCode, event: event),
            command: flags.contains(.command),
            control: flags.contains(.control),
            option: flags.contains(.option),
            shift: flags.contains(.shift)))
    }

    private func finish(_ shortcut: MenubarShortcut?) {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        let completion = self.completion
        self.completion = nil
        completion?(shortcut)
    }

    /// Apple's order: ⌃⌥⇧⌘, then the key.
    private static func label(flags: NSEvent.ModifierFlags, keyCode: Int, event: NSEvent) -> String {
        var label = ""
        if flags.contains(.control) { label += "⌃" }
        if flags.contains(.option) { label += "⌥" }
        if flags.contains(.shift) { label += "⇧" }
        if flags.contains(.command) { label += "⌘" }

        let key = functionKeys[keyCode] ?? namedKeys[keyCode]
            ?? event.charactersIgnoringModifiers?.uppercased() ?? "?"
        return label + key
    }
}
