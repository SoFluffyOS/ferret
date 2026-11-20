import Cocoa

/// Sees drags going on in other apps, from outside: a press, then the drag
/// pasteboard changing while the mouse moves, then the release. It asks
/// for no permission. Global mouse monitors are allowed without
/// Accessibility (key events would not be), and only the drag
/// pasteboard's change count and types are looked at, never what it
/// holds, so the Mac's paste alert has nothing to show. fn and ⇧ come from
/// the mouse events' own modifier flags. Ferret's own drags never reach a
/// global monitor, so they never show here.
final class DragWatcher {
    var onStarted: ((MenubarSystemDrag) -> Void)?
    var onMoved: ((MenubarDragPoint) -> Void)?
    var onEnded: (() -> Void)?

    private var monitors: [Any] = []
    private var changeCountAtPress: Int?
    private var sourceApp: String?
    private var isDragging = false
    private var wakeObserver: NSObjectProtocol?
    /// Checks the button now and then in case a release went unseen.
    private var releaseCheck: Timer?

    private let pasteboard = NSPasteboard(name: .drag)

    /// Types that mean files: plain file URLs, files an app promises
    /// (Photos, Mail) and pictures dragged as data.
    private static let fileTypes: Set<NSPasteboard.PasteboardType> = {
        var types: Set<NSPasteboard.PasteboardType> = [
            .fileURL, .tiff, .png, NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("com.apple.NSFilePromiseItemMetaData"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-content-type"),
            NSPasteboard.PasteboardType("NSPromiseContentsPboardType"),
        ]
        for type in NSFilePromiseReceiver.readableDraggedTypes {
            types.insert(NSPasteboard.PasteboardType(type))
        }
        return types
    }()

    var isWatching: Bool { !monitors.isEmpty }

    func start() {
        guard monitors.isEmpty else { return }

        install()
        // Monitors can go quiet after the Mac sleeps; put them back.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.isWatching else { return }

            self.uninstall()
            self.install()
        }
    }

    func stop() {
        uninstall()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        wakeObserver = nil
        end()
    }

    private func install() {
        let handlers: [(NSEvent.EventTypeMask, (NSEvent) -> Void)] = [
            (.leftMouseDown, { [weak self] event in self?.pressed(event) }),
            (.leftMouseDragged, { [weak self] event in self?.dragged(event) }),
            (.leftMouseUp, { [weak self] _ in self?.end() }),
        ]
        monitors = handlers.compactMap { mask, handler in
            NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        }
    }

    private func uninstall() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors = []
    }

    private func pressed(_ event: NSEvent) {
        end()
        changeCountAtPress = pasteboard.changeCount
        sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func dragged(_ event: NSEvent) {
        guard let pressCount = changeCountAtPress else { return }

        let point = Self.point(for: event)
        if isDragging {
            onMoved?(point)
            return
        }

        // Moving a window or selecting text never touches the drag
        // pasteboard; a real drag writes to it.
        guard pasteboard.changeCount != pressCount, let kind = kind() else { return }

        isDragging = true
        releaseCheck = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard NSEvent.pressedMouseButtons & 1 == 0 else { return }

            self?.end()
        }
        onStarted?(MenubarSystemDrag(kind: kind, point: point, sourceApp: sourceApp))
    }

    private func end() {
        changeCountAtPress = nil
        sourceApp = nil
        releaseCheck?.invalidate()
        releaseCheck = nil
        guard isDragging else { return }

        isDragging = false
        onEnded?()
    }

    /// By types alone: files first, then a web link, then text.
    private func kind() -> MenubarDragKind? {
        guard let types = pasteboard.types, !types.isEmpty else { return nil }

        if types.contains(where: Self.fileTypes.contains) {
            return .files
        }

        if types.contains(.URL) || types.contains(NSPasteboard.PasteboardType("public.url")) {
            return .link
        }

        if types.contains(.string) {
            return .text
        }

        return nil
    }

    private static func point(for event: NSEvent) -> MenubarDragPoint {
        let location = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(location, $0.frame, false) }
            ?? NSScreen.main
        let flags = event.modifierFlags
        return MenubarDragPoint(
            x: location.x,
            y: location.y,
            screen: Self.screen(screen),
            fn: flags.contains(.function),
            shift: flags.contains(.shift))
    }

    static func screen(_ screen: NSScreen?) -> MenubarScreen {
        let frame = screen?.frame ?? .zero
        let visible = screen?.visibleFrame ?? frame
        return MenubarScreen(
            x: frame.minX, y: frame.minY, width: frame.width, height: frame.height,
            visibleX: visible.minX, visibleY: visible.minY,
            visibleWidth: visible.width, visibleHeight: visible.height)
    }
}
