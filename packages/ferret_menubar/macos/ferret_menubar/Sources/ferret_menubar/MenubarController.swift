import Cocoa
import FlutterMacOS

/// Owns the status item and the popover the Flutter view lives in.
final class MenubarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let iconView = StatusItemView()
    private var menuItems: [MenubarMenuItem] = []
    private var detachable = true

    var onMenuItemSelected: ((String) -> Void)?
    var onVisibilityChanged: ((Bool) -> Void)?
    var onFilesDropped: (([String]) -> Void)?

    init(contentViewController: NSViewController, size: NSSize) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        popover.contentViewController = contentViewController
        popover.contentSize = size
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        setUpIconView()
        setIcon(symbolName: "arrow.left.arrow.right", tooltip: nil)
    }

    var isPopoverShown: Bool { popover.isShown }

    func setIcon(symbolName: String, tooltip: String?) {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: tooltip)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = tooltip
    }

    func setPopoverSize(_ size: NSSize) {
        popover.contentSize = size
    }

    func setMenu(_ items: [MenubarMenuItem]) {
        menuItems = items
    }

    func setDetachable(_ detachable: Bool) {
        self.detachable = detachable
    }

    func setShowsInDock(_ shows: Bool) {
        NSApp.setActivationPolicy(shows ? .regular : .accessory)
    }

    func togglePopover() {
        if popover.isShown {
            hidePopover()
            return
        }

        showPopover()
    }

    func showPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func hidePopover() {
        guard popover.isShown else { return }

        popover.performClose(nil)
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        detachable
    }

    func popoverDidShow(_ notification: Notification) {
        statusItem.button?.highlight(true)
        onVisibilityChanged?(true)
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
        onVisibilityChanged?(false)
    }

    // MARK: - Icon interactions

    private func setUpIconView() {
        guard let button = statusItem.button else { return }

        // VoiceOver and keyboard presses reach the button, not the overlay.
        button.target = self
        button.action = #selector(buttonPressed)
        button.setAccessibilityLabel("Ferret")

        iconView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            iconView.topAnchor.constraint(equalTo: button.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])

        iconView.onClick = { [weak self] in self?.togglePopover() }
        iconView.onSecondaryClick = { [weak self] in self?.showMenu() }
        iconView.onDragEntered = { [weak self] in self?.showPopover() }
        iconView.onFilesDropped = { [weak self] paths in self?.onFilesDropped?(paths) }
    }

    private func showMenu() {
        guard let button = statusItem.button, !menuItems.isEmpty else { return }

        let menu = NSMenu()
        for item in menuItems {
            if item.separator {
                menu.addItem(.separator())
                continue
            }

            let menuItem = NSMenuItem(
                title: item.title,
                action: #selector(menuItemSelected(_:)),
                keyEquivalent: item.keyEquivalent ?? "")
            menuItem.target = self
            menuItem.representedObject = item.id
            menuItem.isEnabled = item.enabled
            menu.addItem(menuItem)
        }

        hidePopover()
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    @objc private func buttonPressed() {
        togglePopover()
    }

    @objc private func menuItemSelected(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }

        onMenuItemSelected?(id)
    }
}
