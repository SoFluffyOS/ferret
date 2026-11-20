import Cocoa
import FlutterMacOS

/// A small panel over every app, one more Flutter view on the popover's
/// engine: such as the shelf, shown while something is dragged. It joins
/// every Space and shows over full-screen apps, and it never brings
/// Ferret forward or takes the keyboard unless clicked. Its view is made
/// once and kept, so it comes back at once.
final class FloatingPanelController: NSObject {
    private let engine: FlutterEngine
    private var panel: FloatingPanel?
    private var viewController: FlutterViewController?
    private var dragView: DragDestinationView?
    private var shownFrame: NSRect = .zero
    private var motion: MenubarPanelMotion = .inPlace
    private var hiding = false
    private lazy var canAddViews = MultiView.enable(on: engine)

    var onDragEntered: ((Int64, NSPoint, Int, MenubarDragKind, Bool) -> Void)?
    var onDragUpdated: ((Int64, NSPoint) -> Void)?
    var onDragExited: ((Int64) -> Void)?
    var onDragPerformed: ((Int64, [String], NSPoint) -> Void)?
    var onTextDropped: ((Int64, String, Bool, NSPoint) -> Void)?

    init(engine: FlutterEngine) {
        self.engine = engine
        super.init()
    }

    var viewId: Int64? { viewController?.viewIdentifier }

    var flutterViewController: FlutterViewController? { viewController }

    var isShown: Bool { (panel?.isVisible ?? false) && !hiding }

    private var reducesMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// Shows the panel at [frame], or moves it there when it is shown.
    /// Returns the id of its Flutter view, or nil when this Flutter can't
    /// draw one more.
    func show(frame: NSRect, radius: CGFloat, motion: MenubarPanelMotion) -> Int64? {
        guard let (panel, viewId) = ensurePanel() else { return nil }

        panel.setRadius(radius)
        if isShown {
            move(panel, to: frame, motion: motion)
            return viewId
        }

        hiding = false
        self.motion = motion
        shownFrame = frame
        panel.setFrame(offscreen(frame, motion: motion), display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
            panel.animator().alphaValue = 1
        }
        return viewId
    }

    /// Takes the panel away the way it came in.
    func hide() {
        guard let panel, panel.isVisible, !hiding else { return }

        hiding = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(offscreen(shownFrame, motion: motion), display: true)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self, self.hiding else { return }

            self.hiding = false
            panel.orderOut(nil)
        }
    }

    func setDropAllowed(_ allowed: Bool) {
        dragView?.dropAllowed = allowed
    }

    private func move(_ panel: FloatingPanel, to frame: NSRect, motion: MenubarPanelMotion) {
        self.motion = motion
        shownFrame = frame
        guard reducesMotion else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                panel.animator().setFrame(frame, display: true)
            }
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.setFrame(frame, display: true)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().alphaValue = 1
            }
        }
    }

    /// Where the panel comes from: past the screen's edge for a slide, or
    /// where it is already for a fade (and for anything under Reduce
    /// Motion).
    private func offscreen(_ frame: NSRect, motion: MenubarPanelMotion) -> NSRect {
        guard !reducesMotion else { return frame }

        let travel = frame.width / 2
        switch motion {
        case .fromRight: return frame.offsetBy(dx: travel, dy: 0)
        case .fromLeft: return frame.offsetBy(dx: -travel, dy: 0)
        case .inPlace: return frame.offsetBy(dx: 0, dy: -8)
        }
    }

    private func ensurePanel() -> (FloatingPanel, Int64)? {
        if let panel, let viewController {
            return (panel, viewController.viewIdentifier)
        }

        guard canAddViews else { return nil }

        let panel = FloatingPanel()
        let viewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        let viewId = viewController.viewIdentifier
        viewController.backgroundColor = .clear
        panel.host(viewController.view)
        addDragView(over: viewController.view, viewId: viewId)
        self.panel = panel
        self.viewController = viewController
        return (panel, viewId)
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
}

/// Borderless and non-activating, over full-screen apps and on every
/// Space, with continuous corners and the system's shadow.
final class FloatingPanel: NSPanel {
    private let container = NSView()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        container.wantsLayer = true
        container.layer?.cornerCurve = .continuous
        container.layer?.masksToBounds = true
        contentView = container
    }

    /// Clicked, it takes the keyboard for Space and ⌫ on its tiles, still
    /// without bringing Ferret forward.
    override var canBecomeKey: Bool { true }

    override var canBecomeMain: Bool { false }

    func host(_ view: NSView) {
        view.frame = container.bounds
        view.autoresizingMask = [.width, .height]
        container.addSubview(view)
    }

    func setRadius(_ radius: CGFloat) {
        container.layer?.cornerRadius = radius
        invalidateShadow()
    }
}
