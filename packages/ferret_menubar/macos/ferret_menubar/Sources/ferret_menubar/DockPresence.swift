import Cocoa

/// Decides whether the app shows in the Dock and the app switcher: while
/// the desktop window is open, or always.
final class DockPresence {
    var mode: MenubarDockMode = .whenWindowOpen {
        didSet { apply() }
    }

    var isWindowOpen = false {
        didSet { apply() }
    }

    private func apply() {
        let shows = mode == .always || isWindowOpen
        let policy: NSApplication.ActivationPolicy = shows ? .regular : .accessory
        guard NSApp.activationPolicy() != policy else { return }

        NSApp.setActivationPolicy(policy)
    }
}
