import Cocoa
import FlutterMacOS

/// Owns the desktop window: a second Flutter view on the popover's engine,
/// so both show the same running app. Closing the window removes the view
/// and leaves the app in the menubar; opening it again makes a new view.
final class AppWindowController: NSObject, NSWindowDelegate {
    private let engine: FlutterEngine
    private let dock: DockPresence
    private let window: AppWindow
    private var viewController: FlutterViewController?
    private var dragView: DragDestinationView?
    private var titleBarMonitor: Any?
    private lazy var canAddViews = MultiView.enable(on: engine)

    private static let defaultSize = NSSize(width: 1080, height: 720)
    private static let minimumSize = NSSize(width: 720, height: 480)

    var onOpened: ((Int64) -> Void)?
    var onClosed: ((Int64) -> Void)?
    var onFocusChanged: ((Bool) -> Void)?
    var onDragEntered: ((Int64, NSPoint, Int, MenubarDragKind, Bool) -> Void)?
    var onDragUpdated: ((Int64, NSPoint) -> Void)?
    var onDragExited: ((Int64) -> Void)?
    var onDragPerformed: ((Int64, [String], NSPoint) -> Void)?
    var onTextDropped: ((Int64, String, Bool, NSPoint) -> Void)?

    init(engine: FlutterEngine, dock: DockPresence, title: String) {
        self.engine = engine
        self.dock = dock
        window = AppWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true)
        super.init()

        // The device list runs to the top edge under the traffic lights.
        // The title stays set: VoiceOver and the Window menu read it.
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentMinSize = Self.minimumSize
        window.tabbingMode = .disallowed
        window.center()
        window.setFrameAutosaveName("FerretWindow")
        window.delegate = self
        titleBarMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, self.handleTitleBarClick(event) else { return event }

            return nil
        }
    }

    deinit {
        if let titleBarMonitor {
            NSEvent.removeMonitor(titleBarMonitor)
        }
    }

    /// The Flutter view runs under the title bar, so it would take the
    /// clicks there. The band the traffic lights sit in still moves the
    /// window, and a double click zooms or minimizes it as the person set
    /// in System Settings. Flutter keeps that band free of controls.
    private func handleTitleBarClick(_ event: NSEvent) -> Bool {
        guard event.window === window, let frameView = window.contentView?.superview else { return false }

        let titleBarHeight = window.frame.height - window.contentLayoutRect.height
        let point = event.locationInWindow
        guard point.y >= window.frame.height - titleBarHeight else { return false }

        let hit = frameView.hitTest(frameView.convert(point, from: nil))
        guard !(hit is NSButton) else { return false }

        guard event.clickCount == 2 else {
            window.performDrag(with: event)
            return true
        }

        switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
        case "Minimize": window.performMiniaturize(nil)
        case "None": break
        default: window.performZoom(nil)
        }
        return true
    }

    var isSupported: Bool { MultiView.isAvailable }

    var isOpen: Bool { viewController != nil }

    var viewId: Int64? { viewController?.viewIdentifier }

    var flutterViewController: FlutterViewController? { viewController }

    /// Opens the window, or brings it to the front. Returns the id of its
    /// Flutter view, or nil when this Flutter can't draw a second one.
    @discardableResult
    func open() -> Int64? {
        if let viewController {
            bringToFront()
            return viewController.viewIdentifier
        }

        guard canAddViews else { return nil }

        let viewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        let viewId = viewController.viewIdentifier
        viewController.backgroundColor = .windowBackgroundColor
        viewController.view.frame = NSRect(origin: .zero, size: window.contentLayoutRect.size)
        window.contentViewController = viewController
        self.viewController = viewController
        addDragView(over: viewController.view, viewId: viewId)

        dock.isWindowOpen = true
        bringToFront()
        onOpened?(viewId)
        return viewId
    }

    func close() {
        guard isOpen else { return }

        window.close()
    }

    func setTitle(_ title: String) {
        window.title = title
    }

    func setDropAllowed(_ allowed: Bool) {
        dragView?.dropAllowed = allowed
    }

    private func bringToFront() {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func addDragView(over view: NSView, viewId: Int64) {
        let dragView = DragDestinationView(frame: view.bounds)
        dragView.autoresizingMask = [.width, .height]
        dragView.onEntered = { [weak self] point, count, kind, fromApp in
            self?.onDragEntered?(viewId, point, count, kind, fromApp)
        }
        dragView.onUpdated = { [weak self] point in self?.onDragUpdated?(viewId, point) }
        dragView.onExited = { [weak self] in self?.onDragExited?(viewId) }
        dragView.onPerformed = { [weak self] paths, point in
            self?.onDragPerformed?(viewId, paths, point)
        }
        dragView.onTextPerformed = { [weak self] text, isLink, point in
            self?.onTextDropped?(viewId, text, isLink, point)
        }
        view.addSubview(dragView)
        self.dragView = dragView
    }

    // MARK: - NSWindowDelegate

    func windowDidBecomeKey(_ notification: Notification) {
        onFocusChanged?(true)
    }

    func windowDidResignKey(_ notification: Notification) {
        onFocusChanged?(false)
    }

    /// Letting go of the view controller is what removes its view from the
    /// engine, and Dart hears that through `PlatformDispatcher`.
    func windowWillClose(_ notification: Notification) {
        guard let viewController else { return }

        let viewId = viewController.viewIdentifier
        dragView?.removeFromSuperview()
        dragView = nil
        window.contentViewController = nil
        window.contentView = NSView()
        self.viewController = nil

        dock.isWindowOpen = false
        onClosed?(viewId)
    }
}
