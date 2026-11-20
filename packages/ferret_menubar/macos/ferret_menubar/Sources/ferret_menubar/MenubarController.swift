import Cocoa
import FlutterMacOS

/// Owns the status item and the popover the Flutter view lives in.
final class MenubarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let iconView = StatusItemView()
    private let dragView = DragDestinationView()
    private var menuItems: [MenubarMenuItem] = []
    private var detachable = true
    private var openedByDrag = false
    private var dragLeaveTimer: Timer?
    private var iconState: MenubarIconState = .alone
    private var iconProgress: Double = 0
    private var isDragOverIcon = false
    private let notice = IconNotice()
    private var filesLabel: String?
    private var textLabel: String?
    /// Set when something was dropped in the popover or on the icon after
    /// a drag opened it, so it stays open.
    private var droppedSinceSpring = false
    private var releaseCheck: Timer?

    /// How long the popover waits after a drag leaves it, since people
    /// overshoot, before it closes (only when the drag opened it).
    private let dragLeaveGrace: TimeInterval = 0.6

    var onMenuItemSelected: ((String) -> Void)?
    /// Each mouse event handed to the Flutter view in the popover.
    var onMouseForwarded: ((NSEvent) -> Void)?
    var onVisibilityChanged: ((Bool) -> Void)?
    var onFilesDropped: (([String]) -> Void)?
    var onDragEntered: ((NSPoint, Int, MenubarDragKind, Bool) -> Void)?
    var onDragUpdated: ((NSPoint) -> Void)?
    var onDragExited: (() -> Void)?
    var onDragPerformed: (([String], NSPoint) -> Void)?
    var onTextDropped: ((String, Bool, NSPoint) -> Void)?
    /// Text, or a link when the flag is set, let go on the icon.
    var onIconTextDropped: ((String, Bool) -> Void)?
    /// A drag sprang the popover open.
    var onSprungOpen: (() -> Void)?
    /// The notice's button was pressed.
    var onNoticeAction: (() -> Void)? {
        get { notice.onAction }
        set { notice.onAction = newValue }
    }

    init(contentViewController: NSViewController, size: NSSize) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        popover.contentViewController = contentViewController
        popover.contentSize = size
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        setUpIconView()
        setUpDragView(over: contentViewController.view)
        forwardMouseButtons()
        renderIcon()
    }

    var isPopoverShown: Bool { popover.isShown }

    func setIconState(_ state: MenubarIconState, progress: Double, tooltip: String) {
        iconState = state
        iconProgress = progress
        statusItem.button?.toolTip = tooltip
        statusItem.button?.setAccessibilityLabel(tooltip)
        renderIcon()
    }

    /// A drag over the icon wins while it is there; the state Dart set last
    /// comes back when it leaves.
    private func renderIcon() {
        let shown: MenubarIconState = isDragOverIcon ? .dragOver : iconState
        statusItem.button?.image = StatusIconRenderer.image(for: shown, progress: iconProgress)
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

    func togglePopover() {
        if popover.isShown {
            hidePopover()
            return
        }

        showPopover()
    }

    func showPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }

        openedByDrag = false
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func hidePopover() {
        guard popover.isShown else { return }

        popover.performClose(nil)
    }

    func setDropAllowed(_ allowed: Bool) {
        dragView.dropAllowed = allowed
    }

    func setIconDragBehavior(springOnHover: Bool, opensAtOnce: Bool) {
        iconView.springOnHover = springOnHover
        iconView.opensAtOnce = opensAtOnce
    }

    /// What the label under the icon says while a drag rests on it.
    func setIconDropLabels(files: String?, text: String?) {
        filesLabel = files
        textLabel = text
    }

    func showNotice(_ text: String, action: String?, seconds: TimeInterval) {
        guard let button = statusItem.button else { return }

        notice.show(text, action: action, seconds: seconds, under: button)
    }

    func hideNotice() {
        notice.hide()
    }

    /// After a drop is sent: closes the popover if a drag opened it.
    func closeIfOpenedByDrag() {
        guard openedByDrag else { return }

        hidePopover()
    }

    private func springOpen() {
        guard !popover.isShown else { return }

        notice.hide()
        showPopover()
        openedByDrag = true
        droppedSinceSpring = false
        onSprungOpen?()
        closeWhenDragEndsElsewhere()
    }

    /// Like a spring-loaded folder in Finder: let go anywhere but in the
    /// popover or on the icon, and it closes again.
    private func closeWhenDragEndsElsewhere() {
        releaseCheck?.invalidate()
        releaseCheck = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard NSEvent.pressedMouseButtons & 1 == 0 else { return }

            timer.invalidate()
            // The drop lands a moment after the release.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let self, self.openedByDrag, !self.droppedSinceSpring else { return }

                self.hidePopover()
            }
        }
    }

    private func showDropLabel(for kind: MenubarDragKind?) {
        let label: String? = switch kind {
        case .files: filesLabel
        case .text, .link: textLabel
        case nil: nil
        }
        guard let label, !popover.isShown, let button = statusItem.button else {
            notice.hide()
            return
        }

        notice.show(label, action: nil, seconds: 0, under: button)
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
        openedByDrag = false
        releaseCheck?.invalidate()
        releaseCheck = nil
        dragLeaveTimer?.invalidate()
        statusItem.button?.highlight(false)
        onVisibilityChanged?(false)
    }

    // MARK: - Mouse buttons

    private var mouseMonitor: Any?

    /// AppKit hands mouse presses and scrolls to the Flutter view inside a popover but
    /// never on to its view controller, which is where Flutter reads them
    /// (flutter/flutter#115015; Flutter works around it only before macOS
    /// 13.3.1, and it is back in later releases). Presses on the Flutter view,
    /// docked or detached, go to the controller here instead, and nowhere else.
    private func forwardMouseButtons() {
        // Scroll and trackpad gestures (pan, pinch, rotate) are lost the same way.
        let types: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .scrollWheel, .magnify, .rotate,
        ]
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: types) { [weak self] event in
            guard let controller = self?.popover.contentViewController,
                  controller.isViewLoaded,
                  case let view = controller.view,
                  let window = view.window,
                  event.window === window,
                  let hit = window.contentView?.superview?.hitTest(event.locationInWindow) ?? window.contentView?.hitTest(event.locationInWindow),
                  hit.isDescendant(of: view)
            else { return event }

            self?.onMouseForwarded?(event)
            switch event.type {
            case .leftMouseDown: controller.mouseDown(with: event)
            case .leftMouseUp: controller.mouseUp(with: event)
            case .leftMouseDragged: controller.mouseDragged(with: event)
            case .rightMouseDown: controller.rightMouseDown(with: event)
            case .rightMouseUp: controller.rightMouseUp(with: event)
            case .rightMouseDragged: controller.rightMouseDragged(with: event)
            case .otherMouseDown: controller.otherMouseDown(with: event)
            case .otherMouseUp: controller.otherMouseUp(with: event)
            case .otherMouseDragged: controller.otherMouseDragged(with: event)
            case .scrollWheel: controller.scrollWheel(with: event)
            case .magnify: controller.magnify(with: event)
            case .rotate: controller.rotate(with: event)
            default: return event
            }
            return nil
        }
    }

    // MARK: - Drags over the popover

    /// The drag view rides along inside the Flutter view, so it follows it
    /// into a detached window too.
    private func setUpDragView(over view: NSView) {
        dragView.frame = view.bounds
        dragView.autoresizingMask = [.width, .height]
        view.addSubview(dragView)

        dragView.onEntered = { [weak self] point, count, kind, fromApp in
            self?.dragLeaveTimer?.invalidate()
            self?.onDragEntered?(point, count, kind, fromApp)
        }
        dragView.onUpdated = { [weak self] point in self?.onDragUpdated?(point) }
        dragView.onExited = { [weak self] in
            self?.onDragExited?()
            self?.closeAfterDragLeft()
        }
        dragView.onDropping = { [weak self] in self?.droppedSinceSpring = true }
        dragView.onPerformed = { [weak self] paths, point in self?.onDragPerformed?(paths, point) }
        dragView.onTextPerformed = { [weak self] text, isLink, point in
            self?.onTextDropped?(text, isLink, point)
        }
    }

    private func closeAfterDragLeft() {
        guard openedByDrag else { return }

        dragLeaveTimer?.invalidate()
        dragLeaveTimer = Timer.scheduledTimer(withTimeInterval: dragLeaveGrace, repeats: false) { [weak self] _ in
            self?.closeIfOpenedByDrag()
        }
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
        iconView.onDragHeld = { [weak self] in self?.springOpen() }
        iconView.onFilesDropped = { [weak self] paths in
            self?.droppedSinceSpring = true
            self?.onFilesDropped?(paths)
        }
        iconView.onTextDropped = { [weak self] text, isLink in
            self?.droppedSinceSpring = true
            self?.onIconTextDropped?(text, isLink)
        }
        iconView.onDragOverChanged = { [weak self] kind in
            guard let self else { return }

            self.showDropLabel(for: kind)
            let isOver = kind != nil
            guard self.isDragOverIcon != isOver else { return }

            self.isDragOverIcon = isOver
            self.renderIcon()
        }
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
        // The status item places its own menu under the icon. A menu popped
        // up at a point there opens scrolled past its first item.
        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func buttonPressed() {
        togglePopover()
    }

    @objc private func menuItemSelected(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }

        onMenuItemSelected?(id)
    }
}
