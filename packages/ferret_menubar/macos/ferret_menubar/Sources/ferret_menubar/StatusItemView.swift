import Cocoa

/// Sits over the status bar button: takes clicks and accepts files dropped
/// from other apps. A drag of text or a link springs the popover open too,
/// to be dropped on a device there; dropped on the icon itself, it is
/// refused. So is anything dragged out of Ferret itself (a photo, a clip, a
/// shelf item): it springs the popover open, but never goes to the last
/// device by landing on the icon.
final class StatusItemView: NSView {
    var onClick: (() -> Void)?
    var onSecondaryClick: (() -> Void)?
    /// A file drag rested on the icon for [springDelay].
    var onDragHeld: (() -> Void)?
    var onFilesDropped: (([String]) -> Void)?
    /// A file drag came over the icon (true) or left it, dropped or not.
    var onDragOverChanged: ((Bool) -> Void)?

    /// How long a drag rests on the icon before the popover springs open.
    var springDelay: TimeInterval = 0.3
    private var springTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    override func mouseUp(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            onSecondaryClick?()
            return
        }

        onClick?()
    }

    override func rightMouseUp(with event: NSEvent) {
        onSecondaryClick?()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        let carriesSomething = !fileURLs(from: sender).isEmpty
            || pasteboard.availableType(from: [.URL, .string]) != nil
        guard carriesSomething else { return [] }

        springTimer?.invalidate()
        springTimer = Timer.scheduledTimer(withTimeInterval: springDelay, repeats: false) { [weak self] _ in
            self?.onDragHeld?()
        }
        guard !Self.isFromThisApp(sender) else { return [] }

        onDragOverChanged?(true)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        springTimer?.invalidate()
        springTimer = nil
        onDragOverChanged?(false)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        onDragOverChanged?(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        !Self.isFromThisApp(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        springTimer?.invalidate()
        springTimer = nil
        onDragOverChanged?(false)
        guard !Self.isFromThisApp(sender) else { return false }

        let paths = fileURLs(from: sender).map(\.path)
        guard !paths.isEmpty else { return false }

        onFilesDropped?(paths)
        return true
    }

    /// AppKit gives a drag's source only to views in the app it started in.
    /// Only drags from other apps land on the icon; Ferret's own go to a
    /// device row or the shelf in the popover instead.
    static func isFromThisApp(_ info: NSDraggingInfo) -> Bool {
        info.draggingSource != nil
    }

    private func fileURLs(from info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options)
        return (urls as? [URL]) ?? []
    }
}
