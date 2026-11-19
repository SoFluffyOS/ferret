import Cocoa
import FlutterMacOS

/// Drags files out of a Flutter view to Finder or another app. Flutter
/// sees the press and the first moves; once Dart asks, AppKit's drag takes
/// over from the last mouse event in that view.
final class FileDragSource: NSObject, NSDraggingSource {
    private var lastMouse: NSEvent?
    private var monitor: Any?
    private var dragging: FlutterViewController?

    private static let iconSize: CGFloat = 48
    private static let stackOffset: CGFloat = 6

    override init() {
        super.init()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged]) {
            [weak self] event in
            self?.lastMouse = event
            return event
        }
    }

    /// The popover hands its mouse events to Flutter itself and swallows
    /// them, so it shows them here too.
    func note(_ event: NSEvent) {
        guard [.leftMouseDown, .leftMouseDragged].contains(event.type) else { return }

        lastMouse = event
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    /// False when the mouse isn't pressed in [controller]'s view.
    func start(paths: [String], in controller: FlutterViewController) -> Bool {
        let view = controller.view
        guard !paths.isEmpty, let window = view.window, let event = pressEvent(in: window)
        else { return false }

        let point = view.convert(event.locationInWindow, from: nil)
        let items = paths.enumerated().map { index, path in
            draggingItem(for: path, at: point, stackedAt: CGFloat(index))
        }
        dragging = controller
        view.beginDraggingSession(with: items, event: event, source: self)
        return true
    }

    private func pressEvent(in window: NSWindow) -> NSEvent? {
        let candidates = [lastMouse, NSApp.currentEvent].compactMap { $0 }
        return candidates.first { event in
            event.window === window && [.leftMouseDown, .leftMouseDragged].contains(event.type)
        }
    }

    private func draggingItem(for path: String, at point: NSPoint, stackedAt index: CGFloat)
        -> NSDraggingItem
    {
        let item = NSDraggingItem(pasteboardWriter: URL(fileURLWithPath: path) as NSURL)
        let icon = NSWorkspace.shared.icon(forFile: path)
        let size = Self.iconSize
        icon.size = NSSize(width: size, height: size)
        let offset = index * Self.stackOffset
        item.setDraggingFrame(
            NSRect(x: point.x - size / 2 + offset, y: point.y - size / 2 - offset, width: size, height: size),
            contents: icon)
        return item
    }

    // MARK: - NSDraggingSource

    /// A copy for other apps. Dropped back on Ferret it would send the file
    /// it just received, so the app itself takes nothing.
    func draggingSession(
        _ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        switch context {
        case .outsideApplication: return .copy
        default: return []
        }
    }

    /// The drag ate the release Flutter waits for, which would leave its
    /// press held down. It gets one, where the drag ended.
    func draggingSession(
        _ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation
    ) {
        defer { dragging = nil }
        guard let controller = dragging, let window = controller.view.window else { return }

        let point = window.convertPoint(fromScreen: screenPoint)
        let release = NSEvent.mouseEvent(
            with: .leftMouseUp, location: point, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 0)
        if let release {
            controller.mouseUp(with: release)
        }
    }
}
