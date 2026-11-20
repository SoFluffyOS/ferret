import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

/// Drags files, files still to fetch, and text out of a Flutter view to
/// Finder or another app. Flutter sees the press and the first moves; once
/// Dart asks, AppKit's drag takes over from the last mouse event in that
/// view.
final class FileDragSource: NSObject, NSDraggingSource, NSFilePromiseProviderDelegate {
    private var lastMouse: NSEvent?
    private var monitor: Any?
    private var dragging: FlutterViewController?

    /// Asks Dart for a local copy of a promised file, by its id; nil when
    /// there is none to be had.
    var providePromised: ((String) async -> String?)?

    /// Promised files are written off the main thread, so a slow fetch
    /// never holds up the app the file was dropped on.
    private let promiseQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private static let iconSize: CGFloat = 48
    private static let pictureSize: CGFloat = 72
    private static let stackOffset: CGFloat = 6
    private static let textWidth: CGFloat = 240
    private static let textPadding: CGFloat = 8

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
        begin(in: controller, count: paths.count) { point, index in
            self.draggingItem(for: paths[index], at: point, stackedAt: CGFloat(index))
        }
    }

    /// Like [start], for files fetched only once they are dropped.
    func startPromised(files: [MenubarPromisedFile], in controller: FlutterViewController) -> Bool {
        begin(in: controller, count: files.count) { point, index in
            self.promisedItem(for: files[index], at: point, stackedAt: CGFloat(index))
        }
    }

    /// Like [start], for text; a link goes as a web address too.
    func startText(_ text: String, isLink: Bool, in controller: FlutterViewController) -> Bool {
        guard !text.isEmpty else { return false }

        return begin(in: controller, count: 1) { point, _ in
            self.textItem(for: text, isLink: isLink, at: point)
        }
    }

    private func begin(
        in controller: FlutterViewController, count: Int,
        item: (NSPoint, Int) -> NSDraggingItem
    ) -> Bool {
        let view = controller.view
        guard count > 0, let window = view.window, let event = pressEvent(in: window)
        else { return false }

        let point = view.convert(event.locationInWindow, from: nil)
        let items = (0..<count).map { item(point, $0) }
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
        let url = URL(fileURLWithPath: path)
        let writer: NSPasteboardWriting
        if let type = ImageData.type(of: url.pathExtension) {
            // Some apps take only image data, not a file: give them both.
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(url.absoluteString, forType: .fileURL)
            pasteboardItem.setDataProvider(
                ImageData { completion in completion(path) },
                forTypes: ImageData.pasteboardTypes(for: type))
            writer = pasteboardItem
        } else {
            writer = url as NSURL
        }
        let item = NSDraggingItem(pasteboardWriter: writer)
        let icon = NSWorkspace.shared.icon(forFile: path)
        let size = Self.iconSize
        icon.size = NSSize(width: size, height: size)
        let offset = index * Self.stackOffset
        item.setDraggingFrame(
            NSRect(x: point.x - size / 2 + offset, y: point.y - size / 2 - offset, width: size, height: size),
            contents: icon)
        return item
    }

    private func promisedItem(
        for file: MenubarPromisedFile, at point: NSPoint, stackedAt index: CGFloat
    ) -> NSDraggingItem {
        let type = UTType(filenameExtension: (file.name as NSString).pathExtension) ?? .data
        let provider = ImagePromiseProvider(fileType: type.identifier, delegate: self)
        provider.userInfo = PromisedFile(id: file.id, name: file.name)
        if let imageType = ImageData.type(of: (file.name as NSString).pathExtension) {
            let provide = providePromised
            provider.imageData = ImageData { completion in
                Task { @MainActor in completion(await provide?(file.id) ?? nil) }
            }
            provider.imageTypes = ImageData.pasteboardTypes(for: imageType)
        }
        let item = NSDraggingItem(pasteboardWriter: provider)
        let picture = file.image.flatMap { NSImage(data: $0.data) }
        let contents = picture ?? NSWorkspace.shared.icon(for: type)
        let size = Self.fitted(contents.size, in: picture == nil ? Self.iconSize : Self.pictureSize)
        contents.size = size
        let offset = index * Self.stackOffset
        item.setDraggingFrame(
            NSRect(
                x: point.x - size.width / 2 + offset, y: point.y - size.height / 2 - offset,
                width: size.width, height: size.height),
            contents: contents)
        return item
    }

    private func textItem(for text: String, isLink: Bool, at point: NSPoint) -> NSDraggingItem {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(text, forType: .string)
        if isLink, let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
            url.scheme != nil
        {
            pasteboardItem.setString(url.absoluteString, forType: .URL)
        }
        let item = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let label = Self.label(for: text)
        item.setDraggingFrame(
            NSRect(
                x: point.x - label.size.width / 2, y: point.y - label.size.height / 2,
                width: label.size.width, height: label.size.height),
            contents: label)
        return item
    }

    /// The first line of [text] on a rounded plate, as the drag's picture.
    private static func label(for text: String) -> NSImage {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
        let line = NSAttributedString(string: firstLine, attributes: attributes)
        let textSize = line.size()
        let width = min(textSize.width, textWidth) + textPadding * 2
        let height = ceil(textSize.height) + textPadding * 2
        return NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            let plate = NSBezierPath(roundedRect: rect, xRadius: textPadding, yRadius: textPadding)
            NSColor.windowBackgroundColor.withAlphaComponent(0.9).setFill()
            plate.fill()
            line.draw(
                with: rect.insetBy(dx: textPadding, dy: textPadding),
                options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
            return true
        }
    }

    /// [size] scaled to fit a square of [side], keeping its shape.
    private static func fitted(_ size: NSSize, in side: CGFloat) -> NSSize {
        guard size.width > 0, size.height > 0 else { return NSSize(width: side, height: side) }

        let scale = side / max(size.width, size.height)
        return NSSize(width: size.width * scale, height: size.height * scale)
    }

    // MARK: - NSFilePromiseProviderDelegate

    func filePromiseProvider(
        _ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String
    ) -> String {
        (filePromiseProvider.userInfo as? PromisedFile)?.name ?? "File"
    }

    /// Fetches the file through Dart, then copies it where it was dropped.
    func filePromiseProvider(
        _ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL,
        completionHandler: @escaping (Error?) -> Void
    ) {
        guard let promised = filePromiseProvider.userInfo as? PromisedFile else {
            completionHandler(PromisedFile.Unavailable())
            return
        }

        let provide = providePromised
        Task { @MainActor in
            guard let path = await provide?(promised.id) ?? nil else {
                completionHandler(PromisedFile.Unavailable())
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: url)
                    completionHandler(nil)
                } catch {
                    completionHandler(error)
                }
            }
        }
    }

    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        promiseQueue
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

/// The bytes of a dragged image, made only when the app it was dropped on
/// asks for them: the file's own format, and TIFF for apps that read an
/// NSImage.
final class ImageData: NSObject, NSPasteboardItemDataProvider {
    /// Hands over the local path of the image, or nil when there is none.
    typealias Locate = (@escaping (String?) -> Void) -> Void

    private let locate: Locate

    /// Longest an app waits for a photo still on the phone.
    private static let timeout: TimeInterval = 15

    init(_ locate: @escaping Locate) {
        self.locate = locate
    }

    /// The image type of a file extension; nil for anything else.
    static func type(of pathExtension: String) -> UTType? {
        guard let type = UTType(filenameExtension: pathExtension), type.conforms(to: .image)
        else { return nil }

        return type
    }

    static func pasteboardTypes(for type: UTType) -> [NSPasteboard.PasteboardType] {
        var types = [NSPasteboard.PasteboardType(type.identifier)]
        if type != .tiff {
            types.append(.tiff)
        }
        return types
    }

    /// The image as [type]. The app asks on the main thread and waits, so
    /// the run loop keeps turning meanwhile: a photo still on the phone
    /// arrives through it.
    func data(for type: NSPasteboard.PasteboardType) -> Data? {
        var path: String?
        var done = false
        locate { found in
            path = found
            done = true
        }
        let deadline = Date().addingTimeInterval(Self.timeout)
        while !done, Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
        guard let path, let bytes = FileManager.default.contents(atPath: path) else { return nil }

        guard type == .tiff, ImageData.type(of: (path as NSString).pathExtension) != .tiff else {
            return bytes
        }

        return NSImage(data: bytes)?.tiffRepresentation
    }

    func pasteboard(
        _ pasteboard: NSPasteboard?, item: NSPasteboardItem,
        provideDataForType type: NSPasteboard.PasteboardType
    ) {
        if let data = data(for: type) {
            item.setData(data, forType: type)
        }
    }
}

/// A file promise that also offers the image's bytes, for apps that take
/// image data but not promised files.
final class ImagePromiseProvider: NSFilePromiseProvider {
    var imageData: ImageData?
    var imageTypes: [NSPasteboard.PasteboardType] = []

    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        super.writableTypes(for: pasteboard) + imageTypes
    }

    override func writingOptions(
        forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard
    ) -> NSPasteboard.WritingOptions {
        guard imageTypes.contains(type) else {
            return super.writingOptions(forType: type, pasteboard: pasteboard)
        }

        return .promised
    }

    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard imageTypes.contains(type), let imageData else {
            return super.pasteboardPropertyList(forType: type)
        }

        return imageData.data(for: type)
    }
}

/// What a promise provider carries: the id Dart knows the file by.
private struct PromisedFile {
    let id: String
    let name: String

    struct Unavailable: LocalizedError {
        var errorDescription: String? { "The file couldn't be fetched." }
    }
}
