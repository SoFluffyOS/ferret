import Carbon.HIToolbox
import Cocoa

/// One key combination that reaches the app from anywhere on the Mac.
///
/// Carbon's `RegisterEventHotKey` is used rather than a global `NSEvent`
/// monitor: the monitor sees every key typed in every app, so macOS asks for
/// Accessibility (Input Monitoring) access first, while a hot key hears only
/// its own combination and needs no permission at all.
final class GlobalHotKey {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var registered: MenubarShortcut?

    var onPressed: (() -> Void)?

    /// "FRRT": tells Ferret's hot key apart from any other in the process.
    private static let signature: OSType = 0x4652_5254

    deinit {
        unregister()
        if let handler {
            RemoveEventHandler(handler)
        }
    }

    /// Takes [shortcut] over from the one before, or only drops that one
    /// when it is nil. False when the Mac refused it.
    func register(_ shortcut: MenubarShortcut?) -> Bool {
        unregister()
        registered = shortcut
        return activate()
    }

    /// Lets go of the combination for a while, such as while a new one is
    /// recorded, so pressing it is typed instead.
    func pause() {
        unregister()
    }

    /// Takes the combination back after [pause].
    @discardableResult
    func resume() -> Bool {
        guard hotKey == nil else { return true }

        return activate()
    }

    private func activate() -> Bool {
        guard let shortcut = registered else { return true }

        installHandler()
        let id = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode), Self.carbonModifiers(of: shortcut), id,
            GetApplicationEventTarget(), 0, &hotKey)
        guard status == noErr else {
            hotKey = nil
            return false
        }

        return true
    }

    private func unregister() {
        guard let hotKey else { return }

        UnregisterEventHotKey(hotKey)
        self.hotKey = nil
    }

    private func installHandler() {
        guard handler == nil else { return }

        var pressed = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let me = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }

                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { hotKey.onPressed?() }
                return noErr
            }, 1, &pressed, me, &handler)
    }

    private static func carbonModifiers(of shortcut: MenubarShortcut) -> UInt32 {
        var modifiers = 0
        if shortcut.command { modifiers |= cmdKey }
        if shortcut.control { modifiers |= controlKey }
        if shortcut.option { modifiers |= optionKey }
        if shortcut.shift { modifiers |= shiftKey }
        return UInt32(modifiers)
    }
}
