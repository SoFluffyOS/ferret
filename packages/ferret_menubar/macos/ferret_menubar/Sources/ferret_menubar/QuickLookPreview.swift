import Cocoa
import Quartz

/// Shows files in the Quick Look panel, as Space does in Finder.
final class QuickLookPreview: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private var urls: [URL] = []

    /// Opens the panel on [paths], or closes it when it is open.
    func toggle(paths: [String]) {
        guard let panel = QLPreviewPanel.shared() else { return }

        if QLPreviewPanel.sharedPreviewPanelExists(), panel.isVisible {
            panel.orderOut(nil)
            return
        }

        urls = paths.map { URL(fileURLWithPath: $0) }
        guard !urls.isEmpty else { return }

        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.currentPreviewItemIndex = 0
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }

    /// Space closes the panel again, as in Finder.
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        guard event.type == .keyDown, event.charactersIgnoringModifiers == " " else { return false }

        panel.orderOut(nil)
        return true
    }
}
