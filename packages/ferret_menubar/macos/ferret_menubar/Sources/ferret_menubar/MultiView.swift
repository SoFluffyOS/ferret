import Cocoa
import FlutterMacOS

/// Lets one `FlutterEngine` draw a second view, so the desktop window shows
/// the same running app as the popover instead of a second copy of it.
///
/// The macOS embedder already draws several views per engine, but only
/// hands out view ids past the first once its multi-view switch is on, and
/// its own way in (`enableMultiView`) must run before any view exists. That
/// would take the implicit view away from the popover, and accessibility
/// only reaches the implicit view. So the popover keeps the implicit view
/// and the switch is flipped here, after it. Where a Flutter release no
/// longer has the switch, `isAvailable` is false and there is no window.
enum MultiView {
    private static let switchName = "_multiViewEnabled"

    private static var switchOffset: Int? {
        guard let ivar = class_getInstanceVariable(FlutterEngine.self, switchName),
              let encoding = ivar_getTypeEncoding(ivar),
              ["B", "c"].contains(String(cString: encoding))
        else { return nil }

        return ivar_getOffset(ivar)
    }

    static var isAvailable: Bool { switchOffset != nil }

    /// Returns false when this Flutter can't draw a second view.
    static func enable(on engine: FlutterEngine) -> Bool {
        guard let offset = switchOffset else { return false }

        Unmanaged.passUnretained(engine).toOpaque()
            .advanced(by: offset)
            .assumingMemoryBound(to: ObjCBool.self)
            .pointee = true
        return true
    }
}
