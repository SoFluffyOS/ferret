import Cocoa

/// Sits over the status bar button: takes clicks and accepts dropped files.
final class StatusItemView: NSView {
    var onClick: (() -> Void)?
    var onSecondaryClick: (() -> Void)?
    var onDragEntered: (() -> Void)?
    var onFilesDropped: (([String]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
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
        guard fileURLs(from: sender).isEmpty == false else { return [] }

        onDragEntered?()
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let paths = fileURLs(from: sender).map(\.path)
        guard !paths.isEmpty else { return false }

        onFilesDropped?(paths)
        return true
    }

    private func fileURLs(from info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options)
        return (urls as? [URL]) ?? []
    }
}
