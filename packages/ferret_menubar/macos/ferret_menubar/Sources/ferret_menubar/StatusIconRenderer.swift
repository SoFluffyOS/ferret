import Cocoa

/// Draws the menubar icon for each state: the ferret from
/// branding/ferret-template.svg, with the state drawn over it. Every image but
/// the drag-over one is a template, so the menubar tints it for light and dark
/// by itself.
enum StatusIconRenderer {
    private static let side: CGFloat = 18
    private static let glyphHeight: CGFloat = 16

    /// The ferret down to its waist: with the whole body it is too thin to
    /// read at menubar size.
    private static let glyphBox = NSRect(
        x: FerretGlyph.bounds.minX,
        y: FerretGlyph.bounds.minY,
        width: FerretGlyph.bounds.width,
        height: 860 - FerretGlyph.bounds.minY)

    static func image(for state: MenubarIconState, progress: Double) -> NSImage {
        let size = NSSize(width: side, height: side)
        let image = NSImage(size: size, flipped: false) { bounds in
            draw(state, progress: progress, in: bounds)
            return true
        }
        image.isTemplate = state != .dragOver
        return image
    }

    private static func draw(_ state: MenubarIconState, progress: Double, in bounds: NSRect) {
        switch state {
        case .normal:
            drawGlyph(height: glyphHeight, in: bounds)
        case .alone:
            drawGlyph(height: glyphHeight, in: bounds, color: NSColor.black.withAlphaComponent(0.5))
        case .dragOver:
            drawDragOver(in: bounds)
        case .working:
            drawGlyph(height: 9.5, in: bounds)
            drawRing(progress: progress, in: bounds)
        case .done:
            drawSymbol("checkmark", pointSize: 13, weight: .semibold, in: bounds)
        case .needsYou:
            drawGlyph(height: glyphHeight, in: bounds)
            drawDot(in: bounds)
        case .paused:
            drawGlyph(height: glyphHeight, in: bounds)
            drawSlash(in: bounds)
        }
    }

    private static func symbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
    }

    private static func drawSymbol(
        _ name: String,
        pointSize: CGFloat,
        weight: NSFont.Weight,
        in bounds: NSRect
    ) {
        guard let glyph = symbol(name, pointSize: pointSize, weight: weight) else { return }

        glyph.draw(in: centered(glyph.size, in: bounds))
    }

    /// The ferret, `height` points high and centred in `bounds`. The path is
    /// drawn with y growing downwards, so it is flipped on the way in.
    private static func drawGlyph(height: CGFloat, in bounds: NSRect, color: NSColor = .black) {
        let scale = height / glyphBox.height
        let frame = centered(NSSize(width: glyphBox.width * scale, height: height), in: bounds)

        var transform = AffineTransform(translationByX: frame.minX, byY: frame.maxY)
        transform.scale(x: scale, y: -scale)
        transform.translate(x: -glyphBox.minX, y: -glyphBox.minY)
        let path = FerretGlyph.path()
        path.transform(using: transform)

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: frame).addClip()
        color.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func centered(_ size: NSSize, in bounds: NSRect) -> NSRect {
        NSRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height)
    }

    /// The accent colour as a rounded plate with the glyph in white on it.
    private static func drawDragOver(in bounds: NSRect) {
        NSColor.controlAccentColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5).fill()
        drawGlyph(height: 13, in: bounds, color: .white)
    }

    /// A faint full circle, and over it the part done so far, clockwise
    /// from the top.
    private static func drawRing(progress: Double, in bounds: NSRect) {
        let lineWidth: CGFloat = 1.5
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2 - 0.25

        let track = NSBezierPath()
        track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        track.lineWidth = lineWidth
        NSColor.black.withAlphaComponent(0.3).setStroke()
        track.stroke()

        let fraction = CGFloat(min(max(progress, 0), 1))
        guard fraction > 0 else { return }

        // A whole turn ends where it starts, which draws nothing.
        let sweep = min(360 * fraction, 359.9)
        let done = NSBezierPath()
        done.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: 90,
            endAngle: 90 - sweep,
            clockwise: true)
        done.lineWidth = lineWidth
        done.lineCapStyle = .round
        NSColor.black.setStroke()
        done.stroke()
    }

    /// A dot in the top right corner, with a gap cut around it so it reads
    /// apart from the glyph.
    private static func drawDot(in bounds: NSRect) {
        let radius: CGFloat = 3
        let gap: CGFloat = 1.5
        let center = NSPoint(x: bounds.maxX - radius - 0.5, y: bounds.maxY - radius - 1.5)

        erase {
            NSBezierPath(ovalIn: square(around: center, radius: radius + gap)).fill()
        }
        NSColor.black.setFill()
        NSBezierPath(ovalIn: square(around: center, radius: radius)).fill()
    }

    /// A line from the bottom left to the top right across the ferret, with
    /// a gap cut along it.
    private static func drawSlash(in bounds: NSRect) {
        let inset: CGFloat = 2.5
        let slash = NSBezierPath()
        slash.move(to: NSPoint(x: bounds.minX + inset, y: bounds.minY + inset))
        slash.line(to: NSPoint(x: bounds.maxX - inset, y: bounds.maxY - inset))
        slash.lineCapStyle = .round

        erase {
            slash.lineWidth = 4
            slash.stroke()
        }
        slash.lineWidth = 1.5
        NSColor.black.setStroke()
        slash.stroke()
    }

    private static func erase(_ drawing: () -> Void) {
        guard let context = NSGraphicsContext.current else { return }

        context.saveGraphicsState()
        context.compositingOperation = .destinationOut
        NSColor.black.set()
        drawing()
        context.restoreGraphicsState()
    }

    private static func square(around center: NSPoint, radius: CGFloat) -> NSRect {
        NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}
