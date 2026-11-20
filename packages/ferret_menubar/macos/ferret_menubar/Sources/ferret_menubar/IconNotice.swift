import Cocoa

/// A small label under the menubar icon, like the system's own volume or
/// brightness notices: what a drop there will do ("Send to Pixel 7"), or
/// what one just did, with a button such as Undo. It never takes focus,
/// and it fades away by itself.
final class IconNotice: NSObject {
    private var panel: NSPanel?
    private let label = NSTextField(labelWithString: "")
    private let button = NSButton(title: "", target: nil, action: nil)
    private var hideTimer: Timer?

    /// The button was pressed.
    var onAction: (() -> Void)?

    private static let gap: CGFloat = 4
    private static let radius: CGFloat = 10
    private static let insets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    var isShown: Bool { panel?.isVisible ?? false }

    /// Shows [text] under [anchor], with a button when [action] is set,
    /// for [seconds] (zero keeps it until [hide]).
    func show(_ text: String, action: String?, seconds: TimeInterval, under anchor: NSView) {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        label.stringValue = text
        button.title = action ?? ""
        button.isHidden = action == nil
        button.setAccessibilityLabel(action)

        panel.contentView?.layoutSubtreeIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 160, height: 28)
        panel.setFrame(frame(of: size, under: anchor), display: true)

        hideTimer?.invalidate()
        hideTimer = nil
        if seconds > 0 {
            hideTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                self?.hide()
            }
        }

        if !panel.isVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
        if action != nil {
            announce(text)
        }
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        guard let panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 0
        } completionHandler: {
            guard panel.alphaValue == 0 else { return }

            panel.orderOut(nil)
        }
    }

    @objc private func pressed() {
        hide()
        onAction?()
    }

    private func frame(of size: NSSize, under anchor: NSView) -> NSRect {
        guard let window = anchor.window else { return NSRect(origin: .zero, size: size) }

        let iconFrame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        var origin = NSPoint(
            x: iconFrame.midX - size.width / 2,
            y: iconFrame.minY - Self.gap - size.height)
        if let visible = (window.screen ?? NSScreen.main)?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        }
        return NSRect(origin: origin, size: size)
    }

    /// VoiceOver says it, since the notice never takes focus.
    private func announce(_ text: String) {
        guard let element = panel else { return }

        NSAccessibility.post(
            element: element,
            notification: .announcementRequested,
            userInfo: [
                .announcement: text,
                .priority: NSAccessibilityPriorityLevel.high.rawValue,
            ])
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 28),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true)
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let background = NSVisualEffectView()
        background.material = .popover
        background.state = .active
        background.blendingMode = .behindWindow
        background.wantsLayer = true
        background.layer?.cornerRadius = Self.radius
        background.layer?.cornerCurve = .continuous
        background.layer?.masksToBounds = true

        label.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small), weight: .medium)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        button.target = self
        button.action = #selector(pressed)
        button.isBordered = false
        button.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small), weight: .semibold)
        button.contentTintColor = .controlAccentColor
        button.setButtonType(.momentaryPushIn)

        let stack = NSStackView(views: [label, button])
        stack.orientation = .horizontal
        stack.spacing = 12
        stack.edgeInsets = Self.insets
        stack.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            stack.topAnchor.constraint(equalTo: background.topAnchor),
            stack.bottomAnchor.constraint(equalTo: background.bottomAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
        panel.contentView = background
        return panel
    }
}
