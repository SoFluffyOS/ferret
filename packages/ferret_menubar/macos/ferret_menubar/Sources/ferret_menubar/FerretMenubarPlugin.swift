import Cocoa
import FlutterMacOS

/// Runs the app from the menubar. In `MainFlutterWindow.awakeFromNib`, run a
/// `FlutterEngine` yourself (so Dart starts before the popover first opens),
/// register plugins on it, then call `FerretMenubarPlugin.install` with a
/// controller for that engine. Set `LSUIElement` in Info.plist so the app
/// starts without a Dock icon.
public class FerretMenubarPlugin: NSObject, FlutterPlugin, MenubarHostApi {
    private static var controller: MenubarController?
    private static var flutterApi: MenubarFlutterApi?

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
        controller.onDragEntered = { point, count in
            Task { @MainActor in
                try? await flutterApi?.onDragEntered(x: point.x, y: point.y, fileCount: Int64(count))
            }
        }
        controller.onDragUpdated = { point in
            Task { @MainActor in try? await flutterApi?.onDragUpdated(x: point.x, y: point.y) }
        }
        controller.onDragExited = {
            Task { @MainActor in try? await flutterApi?.onDragExited() }
        }
        controller.onDragPerformed = { paths, point in
            Task { @MainActor in
                try? await flutterApi?.onDragPerformed(paths: paths, x: point.x, y: point.y)
            }
        }
        self.controller = controller
    }

    func setIcon(symbolName: String, tooltip: String?) throws {
        Self.controller?.setIcon(symbolName: symbolName, tooltip: tooltip)
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

    func setShowsInDock(shows: Bool) throws {
        Self.controller?.setShowsInDock(shows)
    }

    func setDropAllowed(allowed: Bool) throws {
        Self.controller?.setDropAllowed(allowed)
    }

    func closeIfOpenedByDrag() throws {
        Self.controller?.closeIfOpenedByDrag()
    }

    func setDetachable(detachable: Bool) throws {
        Self.controller?.setDetachable(detachable)
    }
}
