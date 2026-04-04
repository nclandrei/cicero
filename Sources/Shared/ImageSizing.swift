import Foundation

/// Computes display-width constraints for images rendered inside slide previews.
public enum ImageSizing {
    public static let maxAllowedWidth: CGFloat = 1600
    public static let minAllowedWidth: CGFloat = 100

    /// Returns the max display width for a slide image.
    ///
    /// - Parameters:
    ///   - explicitWidth: Width from a `#w=N` URL fragment, if any.
    ///   - naturalWidth: The image's intrinsic pixel width.
    /// - Returns: The width to use as `maxWidth` / `width` frame constraint.
    public static func constrainedWidth(
        explicitWidth: CGFloat?,
        naturalWidth: CGFloat
    ) -> CGFloat {
        if let explicitWidth {
            return max(minAllowedWidth, min(explicitWidth, maxAllowedWidth))
        }
        return min(naturalWidth, maxAllowedWidth)
    }
}
