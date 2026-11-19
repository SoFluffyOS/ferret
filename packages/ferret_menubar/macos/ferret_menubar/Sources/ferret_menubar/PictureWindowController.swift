import Cocoa
import FlutterMacOS

/// Owns the picture window: one more Flutter view on the popover's engine,
/// in a window that has the shape of what it shows, such as a phone's
/// screen. The shape is locked while it is resized, the window turns when
/// the picture does, and each id gets its size and place back.
///
/// With a bar, the Flutter view also runs under the transparent title bar:
/// the top `bar` points hold the traffic lights and Flutter's controls, and
/// the picture fills everything below in its own shape. Sizes here are
/// the picture's, and the bar is added on top.
final class PictureWindowController: NSObject, NSWindowDelegate {
    private let engine: FlutterEngine
    private let dock: DockPresence
    private let defaults: UserDefaults
    private var window: PictureWindow?
    private var viewController: FlutterViewController?
    private var id: String?
    private var picture = NSSize(width: 9, height: 16)
    private var bar: CGFloat = 0
    private lazy var canAddViews = MultiView.enable(on: engine)

    /// The short side never gets smaller than this.
    private static let minimumShortSide: CGFloat = 240
    /// How much of the screen's height the picture takes the first time.
    private static let firstShare: CGFloat = 0.8
    private static let stepFactor: CGFloat = 1.25
    private static let defaultsPrefix = "FerretPictureWindow."

    var onClosed: ((Int64) -> Void)?

    init(engine: FlutterEngine, dock: DockPresence, defaults: UserDefaults = .standard) {
        self.engine = engine
        self.dock = dock
        self.defaults = defaults
        super.init()
    }

    var isOpen: Bool { viewController != nil }

    /// Opens the window for `id`, or brings it to the front when it is the
    /// one open. Another id takes the open window's place. Returns the id
    /// of its Flutter view, or nil when this Flutter can't draw one more.
    func open(id: String, title: String, picture: NSSize, bar: CGFloat = 0) -> Int64? {
        if let viewController, self.id == id {
            window?.title = title
            bringToFront()
            return viewController.viewIdentifier
        }

        close()
        guard canAddViews, picture.width > 0, picture.height > 0 else { return nil }

        self.id = id
        self.picture = picture
        self.bar = max(0, bar)
        var style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        if self.bar > 0 {
            style.insert(.fullSizeContentView)
        }
        let window = PictureWindow(
            contentRect: NSRect(origin: .zero, size: picture),
            styleMask: style,
            backing: .buffered,
            defer: true)
        // The title stays set: VoiceOver and the Window menu read it.
        window.title = title
        if self.bar > 0 {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.collectionBehavior = [.fullScreenNone]
        window.backgroundColor = .black
        window.delegate = self
        window.onStep = { [weak self] step in self?.resize(step) }

        let viewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        viewController.backgroundColor = .black
        window.contentViewController = viewController
        self.window = window
        self.viewController = viewController

        applyShape()
        place(window)
        dock.isPictureWindowOpen = true
        bringToFront()
        return viewController.viewIdentifier
    }

    /// The picture has another size now. A phone that was turned turns the
    /// window around its centre, with its long side as long as before.
    func setPicture(_ picture: NSSize) {
        guard let window, picture.width > 0, picture.height > 0, picture != self.picture else {
            return
        }

        let longSide = pictureLongSide(of: window)
        self.picture = picture
        applyShape()
        setContent(size(longSide: longSide), of: window, animated: true)
        remember()
    }

    func focus() {
        guard isOpen else { return }

        bringToFront()
    }

    /// Moves the window with the pointer, from a press Flutter saw on the
    /// bar. Flutter's view takes every click there, so it asks.
    func drag() {
        guard let window, let event = window.currentEvent ?? NSApp.currentEvent,
            event.type == .leftMouseDown || event.type == .leftMouseDragged
        else { return }

        window.performDrag(with: event)
    }

    func close() {
        window?.close()
    }

    private func resize(_ step: PictureWindowStep) {
        guard let window else { return }

        let scale = window.backingScaleFactor
        let current = pictureLongSide(of: window)
        let longSide: CGFloat
        switch step {
        case .actual: longSide = max(picture.width, picture.height) / scale
        case .larger: longSide = current * Self.stepFactor
        case .smaller: longSide = current / Self.stepFactor
        }

        setContent(size(longSide: longSide), of: window, animated: true)
        remember()
    }

    /// The shape is kept in `windowWillResize`, as the bar on top is a
    /// fixed height that a plain aspect ratio can't add.
    private func applyShape() {
        guard let window else { return }

        window.contentMinSize = size(longSide: 0)
    }

    /// The content size for a picture with this long side, never under the
    /// minimum: the picture in its own shape, and the bar on top.
    private func size(longSide: CGFloat) -> NSSize {
        let picture = PictureShape.size(
            of: self.picture, longSide: longSide, minimumShortSide: Self.minimumShortSide)
        return NSSize(width: picture.width, height: picture.height + bar)
    }

    private static func longSide(of size: NSSize) -> CGFloat {
        max(size.width, size.height)
    }

    /// The long side of the picture a content of this size shows.
    private func pictureLongSide(ofContent content: NSSize) -> CGFloat {
        Self.longSide(of: NSSize(width: content.width, height: max(0, content.height - bar)))
    }

    private func pictureLongSide(of window: NSWindow) -> CGFloat {
        pictureLongSide(ofContent: contentSize(of: window))
    }

    private func contentSize(of window: NSWindow) -> NSSize {
        window.contentRect(forFrameRect: window.frame).size
    }

    /// Where the window was for this id, or the first size in the middle
    /// of the screen: as tall as most of the screen, never bigger than the
    /// picture itself.
    private func place(_ window: NSWindow) {
        if let id, let saved = defaults.dictionary(forKey: Self.defaultsPrefix + id),
            let longSide = saved["long"] as? Double,
            let x = saved["x"] as? Double,
            let y = saved["y"] as? Double
        {
            let content = size(longSide: CGFloat(longSide))
            var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: content))
            frame.origin = NSPoint(x: x, y: y)
            window.setFrame(fitted(frame, to: screen(for: frame)), display: false)
            return
        }

        let screen = NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let scale = screen?.backingScaleFactor ?? 2
        let chrome = window.frameRect(forContentRect: .zero).height
        let actual = NSSize(width: picture.width / scale, height: picture.height / scale)
        let room = NSSize(
            width: visible.width * Self.firstShare,
            height: visible.height * Self.firstShare - chrome - bar)
        let shrink = min(1, room.width / actual.width, room.height / actual.height)
        let content = size(longSide: Self.longSide(of: actual) * shrink)
        window.setContentSize(content)
        window.center()
    }

    private func setContent(_ content: NSSize, of window: NSWindow, animated: Bool) {
        let centre = NSPoint(x: window.frame.midX, y: window.frame.midY)
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: content))
        frame.origin = NSPoint(x: centre.x - frame.width / 2, y: centre.y - frame.height / 2)
        window.setFrame(fitted(frame, to: window.screen), display: true, animate: animated)
    }

    private func screen(for frame: NSRect) -> NSScreen? {
        NSScreen.screens.first { $0.visibleFrame.intersects(frame) } ?? NSScreen.main
    }

    /// The frame made to fit the screen: smaller in the picture's shape
    /// when it is too big, then moved until all of it shows.
    private func fitted(_ frame: NSRect, to screen: NSScreen?) -> NSRect {
        guard let window, let visible = screen?.visibleFrame else { return frame }

        var content = window.contentRect(forFrameRect: frame).size
        let chrome = frame.height - content.height
        let pictureHeight = max(1, content.height - bar)
        let shrink = min(
            1, visible.width / content.width, (visible.height - chrome - bar) / pictureHeight)
        if shrink < 1 {
            content = size(longSide: pictureLongSide(ofContent: content) * shrink)
        }

        var fitted = window.frameRect(forContentRect: NSRect(origin: .zero, size: content))
        fitted.origin = NSPoint(
            x: frame.midX - fitted.width / 2,
            y: frame.midY - fitted.height / 2)
        fitted.origin.x = min(max(fitted.minX, visible.minX), visible.maxX - fitted.width)
        fitted.origin.y = min(max(fitted.minY, visible.minY), visible.maxY - fitted.height)
        return fitted
    }

    private func remember() {
        guard let window, let id else { return }

        defaults.set(
            [
                "long": Double(pictureLongSide(of: window)),
                "x": Double(window.frame.minX),
                "y": Double(window.frame.minY),
            ],
            forKey: Self.defaultsPrefix + id)
    }

    private func bringToFront() {
        guard let window else { return }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - NSWindowDelegate

    /// Keeps the picture's shape under the bar: the side the person moved
    /// most leads, and the other follows.
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let chrome = sender.frame.height - contentSize(of: sender).height
        let proposed = NSSize(width: frameSize.width, height: frameSize.height - chrome)
        let current = contentSize(of: sender)
        let content = PictureShape.content(
            proposed: proposed, current: current, picture: picture, bar: bar,
            minimum: size(longSide: 0))
        return NSSize(width: content.width, height: content.height + chrome)
    }

    /// The green button makes the window as big as the screen allows, in
    /// the picture's shape.
    func windowWillUseStandardFrame(_ window: NSWindow, defaultFrame newFrame: NSRect) -> NSRect {
        let largest = size(longSide: .greatestFiniteMagnitude / 4)
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: largest))
        frame.origin = NSPoint(x: window.frame.midX, y: window.frame.midY)
        return fitted(frame, to: window.screen)
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        remember()
    }

    func windowDidMove(_ notification: Notification) {
        remember()
    }

    /// Letting go of the view controller is what removes its view from the
    /// engine, and Dart hears that through `PlatformDispatcher`.
    func windowWillClose(_ notification: Notification) {
        guard let window, let viewController else { return }

        remember()
        let viewId = viewController.viewIdentifier
        window.delegate = nil
        window.contentViewController = nil
        window.contentView = NSView()
        self.viewController = nil
        self.window = nil
        id = nil

        dock.isPictureWindowOpen = false
        onClosed?(viewId)
    }
}
