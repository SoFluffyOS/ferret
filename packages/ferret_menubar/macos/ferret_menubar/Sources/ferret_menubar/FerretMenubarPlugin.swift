import Cocoa
import FlutterMacOS

/// Runs the app from the menubar. In `MainFlutterWindow.awakeFromNib`, run a
/// `FlutterEngine` yourself (so Dart starts before the popover first opens),
/// register plugins on it, then call `FerretMenubarPlugin.install` with a
/// controller for that engine. Set `LSUIElement` in Info.plist so the app
/// starts without a Dock icon. The same engine also draws the desktop window
/// (`openWindow`), so the popover and the window are one running app.
public class FerretMenubarPlugin: NSObject, FlutterPlugin, MenubarHostApi {
    private static var controller: MenubarController?
    private static var windowController: AppWindowController?
    private static var pictureController: PictureWindowController?
    private static var popoverViewId: Int64 = 0
    private static let dock = DockPresence()
    private static var flutterApi: MenubarFlutterApi?
    private static let hotKey = GlobalHotKey()
    private static let recorder = ShortcutRecorder()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FerretMenubarPlugin()
        MenubarHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        flutterApi = MenubarFlutterApi(binaryMessenger: registrar.messenger)
    }

    /// Moves [flutterViewController] into a menubar popover and hides [window].
    /// Its engine should already be running, so the popover opens instantly.
    public static func install(
        flutterViewController: FlutterViewController,
        hiding window: NSWindow,
        size: NSSize = NSSize(width: 380, height: 560)
    ) {
        window.contentViewController = nil
        window.orderOut(nil)

        flutterViewController.view.frame = NSRect(origin: .zero, size: size)

        let controller = MenubarController(contentViewController: flutterViewController, size: size)
        controller.onMenuItemSelected = { id in
            Task { @MainActor in try? await flutterApi?.onMenuItemSelected(id: id) }
        }
        controller.onVisibilityChanged = { shown in
            Task { @MainActor in try? await flutterApi?.onPopoverVisibilityChanged(shown: shown) }
        }
        controller.onFilesDropped = { paths in
            Task { @MainActor in try? await flutterApi?.onFilesDropped(paths: paths) }
        }
        let popoverViewId = flutterViewController.viewIdentifier
        controller.onDragEntered = { point, count in dragEntered(popoverViewId, point, count) }
        controller.onDragUpdated = { point in dragUpdated(popoverViewId, point) }
        controller.onDragExited = { dragExited(popoverViewId) }
        controller.onDragPerformed = { paths, point in dragPerformed(popoverViewId, paths, point) }
        self.popoverViewId = popoverViewId
        self.controller = controller

        let windowController = AppWindowController(
            engine: flutterViewController.engine, dock: dock, title: window.title)
        windowController.onOpened = { viewId in
            Task { @MainActor in try? await flutterApi?.onWindowOpened(viewId: viewId) }
        }
        windowController.onFocusChanged = { focused in
            Task { @MainActor in try? await flutterApi?.onWindowFocusChanged(focused: focused) }
        }
        windowController.onClosed = { viewId in
            Task { @MainActor in try? await flutterApi?.onWindowClosed(viewId: viewId) }
        }
        windowController.onDragEntered = dragEntered
        windowController.onDragUpdated = dragUpdated
        windowController.onDragExited = dragExited
        windowController.onDragPerformed = dragPerformed
        self.windowController = windowController

        let pictureController = PictureWindowController(
            engine: flutterViewController.engine, dock: dock)
        pictureController.onClosed = { viewId in
            Task { @MainActor in try? await flutterApi?.onPictureWindowClosed(viewId: viewId) }
        }
        self.pictureController = pictureController

        hotKey.onPressed = { [weak controller] in controller?.togglePopover() }
    }

    /// Opens the desktop window, or brings it to the front: for the Dock
    /// icon, from `applicationShouldHandleReopen`. False when there is none.
    @discardableResult
    public static func openWindow() -> Bool {
        windowController?.open() != nil
    }

    private static func dragEntered(_ viewId: Int64, _ point: NSPoint, _ count: Int) {
        Task { @MainActor in
            try? await flutterApi?.onDragEntered(
                viewId: viewId, x: point.x, y: point.y, fileCount: Int64(count))
        }
    }

    private static func dragUpdated(_ viewId: Int64, _ point: NSPoint) {
        Task { @MainActor in
            try? await flutterApi?.onDragUpdated(viewId: viewId, x: point.x, y: point.y)
        }
    }

    private static func dragExited(_ viewId: Int64) {
        Task { @MainActor in try? await flutterApi?.onDragExited(viewId: viewId) }
    }

    private static func dragPerformed(_ viewId: Int64, _ paths: [String], _ point: NSPoint) {
        Task { @MainActor in
            try? await flutterApi?.onDragPerformed(
                viewId: viewId, paths: paths, x: point.x, y: point.y)
        }
    }

    func setIconState(state: MenubarIconState, progress: Double, tooltip: String) throws {
        Self.controller?.setIconState(state, progress: progress, tooltip: tooltip)
    }

    func setPopoverSize(width: Double, height: Double) throws {
        Self.controller?.setPopoverSize(NSSize(width: width, height: height))
    }

    func showPopover() throws {
        Self.controller?.showPopover()
    }

    func hidePopover() throws {
        Self.controller?.hidePopover()
    }

    func isPopoverShown() throws -> Bool {
        Self.controller?.isPopoverShown ?? false
    }

    func setMenu(items: [MenubarMenuItem]) throws {
        Self.controller?.setMenu(items)
    }

    func setDockMode(mode: MenubarDockMode) throws {
        Self.dock.mode = mode
    }

    func isWindowSupported() throws -> Bool {
        Self.windowController?.isSupported ?? false
    }

    func openWindow() throws -> Int64 {
        guard let viewId = Self.windowController?.open() else {
            throw PigeonError(
                code: "window-unsupported",
                message: "This Flutter can't draw a second view.",
                details: nil)
        }

        return viewId
    }

    func closeWindow() throws {
        Self.windowController?.close()
    }

    func isWindowOpen() throws -> Bool {
        Self.windowController?.isOpen ?? false
    }

    func setWindowTitle(title: String) throws {
        Self.windowController?.setTitle(title)
    }

    func openPictureWindow(id: String, title: String, width: Double, height: Double) throws
        -> Int64
    {
        let picture = NSSize(width: width, height: height)
        guard let viewId = Self.pictureController?.open(id: id, title: title, picture: picture)
        else {
            throw PigeonError(
                code: "window-unsupported",
                message: "This Flutter can't draw one more view.",
                details: nil)
        }

        return viewId
    }

    func setPictureWindowSize(width: Double, height: Double) throws {
        Self.pictureController?.setPicture(NSSize(width: width, height: height))
    }

    func focusPictureWindow() throws {
        Self.pictureController?.focus()
    }

    func closePictureWindow() throws {
        Self.pictureController?.close()
    }

    func setDropAllowed(viewId: Int64, allowed: Bool) throws {
        if viewId == Self.popoverViewId {
            Self.controller?.setDropAllowed(allowed)
            return
        }

        guard viewId == Self.windowController?.viewId else { return }

        Self.windowController?.setDropAllowed(allowed)
    }

    func closeIfOpenedByDrag() throws {
        Self.controller?.closeIfOpenedByDrag()
    }

    func setGlobalShortcut(shortcut: MenubarShortcut?) throws -> Bool {
        Self.hotKey.register(shortcut)
    }

    func recordShortcut() async throws -> MenubarShortcut? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                Self.hotKey.pause()
                Self.recorder.record { shortcut in
                    Self.hotKey.resume()
                    continuation.resume(returning: shortcut)
                }
            }
        }
    }

    func cancelRecording() throws {
        Self.recorder.cancel()
    }

    func setDetachable(detachable: Bool) throws {
        Self.controller?.setDetachable(detachable)
    }
}
