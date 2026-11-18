import Cocoa

/// Lies over the Flutter view and takes file drags for it. Flutter's own
/// drop plugins look for the view's window when they register, which the
/// popover doesn't have yet, so drags are caught here and handed to Dart.
/// It never takes clicks: `hitTest` returns nil.
final class DragDestinationView: NSView {
    var onEntered: ((NSPoint, Int) -> Void)?
    var onUpdated: ((NSPoint) -> Void)?
    var onExited: (() -> Void)?
    var onPerformed: (([String], NSPoint) -> Void)?

    private var accepting = false

    /// Whether a drop where the pointer is now would be taken; Dart says so
    /// as the pointer moves over its targets.
    var dropAllowed = true

    private lazy var promiseQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerTypes()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerTypes()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let count = itemCount(in: sender)
        accepting = count > 0
        guard accepting else { return [] }

        dropAllowed = true
        onEntered?(flutterPoint(sender), count)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard accepting else { return [] }

        onUpdated?(flutterPoint(sender))
        return dropAllowed ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        guard accepting else { return }

        accepting = false
        onExited?()
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        guard accepting else { return }

        accepting = false
        onExited?()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        accepting && dropAllowed
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        accepting = false
        let point = flutterPoint(sender)
        let paths = fileURLs(from: sender).map(\.path)
        let promises = filePromises(from: sender)
        guard !paths.isEmpty || !promises.isEmpty else {
            onExited?()
            return false
        }

        guard !promises.isEmpty else {
            onPerformed?(paths, point)
            return true
        }

        receive(promises) { [weak self] received in
            self?.onPerformed?(paths + received, point)
        }
        return true
    }

    private func registerTypes() {
        registerForDraggedTypes([.fileURL] + NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
    }

    /// Flutter's logical pixels are points with the origin at the top left.
    private func flutterPoint(_ info: NSDraggingInfo) -> NSPoint {
        let local = convert(info.draggingLocation, from: nil)
        return NSPoint(x: local.x, y: bounds.height - local.y)
    }

    private func itemCount(in info: NSDraggingInfo) -> Int {
        let files = fileURLs(from: info).count
        let promises = filePromises(from: info).count
        return files + promises
    }

    private func fileURLs(from info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options)
        return (urls as? [URL]) ?? []
    }

    private func filePromises(from info: NSDraggingInfo) -> [NSFilePromiseReceiver] {
        let promises = info.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil)
        return (promises as? [NSFilePromiseReceiver]) ?? []
    }

    /// Files promised by apps such as Photos or Mail are written to a fresh
    /// temporary folder first, then sent like any other file.
    private func receive(_ promises: [NSFilePromiseReceiver], completion: @escaping ([String]) -> Void) {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("ferret-drops", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let lock = NSLock()
        var remaining = promises.reduce(0) { $0 + max($1.fileNames.count, 1) }
        var received: [String] = []
        for promise in promises {
            promise.receivePromisedFiles(atDestination: folder, options: [:], operationQueue: promiseQueue) { url, error in
                lock.lock()
                if error == nil {
                    received.append(url.path)
                }
                remaining -= 1
                let done = remaining == 0
                let paths = received
                lock.unlock()

                guard done else { return }

                DispatchQueue.main.async { completion(paths) }
            }
        }
    }
}
