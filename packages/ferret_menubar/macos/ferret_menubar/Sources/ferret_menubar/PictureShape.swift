import Foundation

/// The picture window's sizes as plain numbers: a picture in its own
/// shape, with a bar of fixed height on top of it.
enum PictureShape {
    /// The picture's size with this long side, never with a short side
    /// under `minimumShortSide`.
    static func size(of picture: NSSize, longSide: CGFloat, minimumShortSide: CGFloat) -> NSSize {
        let aspect = picture.width / picture.height
        let shortShare = min(aspect, 1 / aspect)
        let long = max(longSide, minimumShortSide / shortShare)
        return aspect >= 1
            ? NSSize(width: long, height: long / aspect)
            : NSSize(width: long * aspect, height: long)
    }

    /// The content size nearest to `proposed` that shows the picture whole
    /// under the bar, with nothing around it. The side that moved most
    /// from `current` leads; nothing goes under `minimum`.
    static func content(
        proposed: NSSize, current: NSSize, picture: NSSize, bar: CGFloat, minimum: NSSize
    ) -> NSSize {
        let aspect = picture.width / picture.height
        let widthLeads =
            abs(proposed.width - current.width) >= abs(proposed.height - current.height)
        let pictureWidth: CGFloat
        if widthLeads {
            pictureWidth = proposed.width
        } else {
            pictureWidth = (proposed.height - bar) * aspect
        }

        let width = max(pictureWidth, minimum.width)
        return NSSize(width: width, height: width / aspect + bar)
    }
}
