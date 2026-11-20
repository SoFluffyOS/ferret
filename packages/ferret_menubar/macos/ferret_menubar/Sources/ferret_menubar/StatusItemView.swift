import Cocoa

/// Sits over the status bar button: takes clicks and drops from other
/// apps. Files let go on it go where Dart says (a device or the shelf);
/// text and links go to Dart too. A drag resting on it for the Mac's
/// spring-loading delay, or force-clicked, springs the popover open.
/// Anything dragged out of Ferret itself (a photo, a clip, a shelf item)
/// springs the popover open too, but never lands on the icon.
final class StatusItemView: NSView, NSSpringLoadingDestination {
    var onClick: (() -> Void)?
    var onSecondaryClick: (() -> Void)?
    /// A drag rested on the icon, was force-clicked there, or came over it
    /// while it opens at once.
    var onDragHeld: (() -> Void)?
    var onFilesDropped: (([String]) -> Void)?
    /// Text, or a link when the flag is set, let go on the icon.
    var onTextDropped: ((String, Bool) -> Void)?
    /// A drag from another app came over the icon, with what it carries,
    /// or left it (nil), dropped or not.
    var onDragOverChanged: ((MenubarDragKind?) -> Void)?

    /// A drag resting here opens the popover, after the Mac's own delay.
    var springOnHover = true
    /// A drag coming over the icon opens the popover at once.
    var opensAtOnce = false

    private var springTimer: Timer?
    private var heldThisDrag = false

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
        guard let kind = kindOf(sender) else { return [] }

        heldThisDrag = false
        springTimer?.invalidate()
        springTimer = nil
        if opensAtOnce {
            hold()
        } else if springOnHover, SpringLoading.isEnabled {
            springTimer = Timer.scheduledTimer(
                withTimeInterval: SpringLoading.delay, repeats: false
            ) { [weak self] _ in self?.hold() }
        }
        guard !Self.isFromThisApp(sender) else { return [] }

        onDragOverChanged?(kind)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        springTimer?.invalidate()
        springTimer = nil
        onDragOverChanged?(nil)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        springTimer?.invalidate()
        springTimer = nil
        onDragOverChanged?(nil)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        !Self.isFromThisApp(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        springTimer?.invalidate()
        springTimer = nil
        onDragOverChanged?(nil)
        guard !Self.isFromThisApp(sender) else { return false }

        let paths = fileURLs(from: sender).map(\.path)
        if !paths.isEmpty {
            onFilesDropped?(paths)
            return true
        }

        if let link = webLink(from: sender) {
            onTextDropped?(link.absoluteString, true)
            return true
        }

        if let text = text(from: sender) {
            onTextDropped?(text, false)
            return true
        }

        return false
    }

    // MARK: - NSSpringLoadingDestination

    /// AppKit adds force click and the Mac's own hover delay; the timer
    /// above covers the hover where AppKit doesn't call for a status item.
    func springLoadingActivated(_ activated: Bool, draggingInfo: NSDraggingInfo) {
        guard activated else { return }

        hold()
    }

    func springLoadingHighlightChanged(_ draggingInfo: NSDraggingInfo) {}

    func springLoadingEntered(_ draggingInfo: NSDraggingInfo) -> NSSpringLoadingOptions {
        guard springOnHover || opensAtOnce, kindOf(draggingInfo) != nil else { return [] }

        return .enabled
    }

    private func hold() {
        springTimer?.invalidate()
        springTimer = nil
        guard !heldThisDrag else { return }

        heldThisDrag = true
        onDragHeld?()
    }

    /// AppKit gives a drag's source only to views in the app it started in.
    /// Only drags from other apps land on the icon; Ferret's own go to a
    /// device row or the shelf in the popover instead.
    static func isFromThisApp(_ info: NSDraggingInfo) -> Bool {
        info.draggingSource != nil
    }

    /// Files win, since a file drag also carries its name as text.
    private func kindOf(_ info: NSDraggingInfo) -> MenubarDragKind? {
        let pasteboard = info.draggingPasteboard
        if !fileURLs(from: info).isEmpty {
            return .files
        }

        if pasteboard.availableType(from: [.URL]) != nil {
            return .link
        }

        if pasteboard.availableType(from: [.string]) != nil {
            return .text
        }

        return nil
    }

    private func fileURLs(from info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options)
        return (urls as? [URL]) ?? []
    }

    private func webLink(from info: NSDraggingInfo) -> URL? {
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil)
        let link = (urls as? [URL])?.first { !$0.isFileURL }
        guard let link, let scheme = link.scheme?.lowercased(), ["http", "https"].contains(scheme)
        else { return nil }

        return link
    }

    private func text(from info: NSDraggingInfo) -> String? {
        guard let text = info.draggingPasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        return text
    }
}
