import Foundation

public struct ThemeDefinition: Codable, Sendable, Equatable {
    public let name: String
    public let background: String
    public let text: String
    public let heading: String
    public let accent: String
    public let codeBackground: String
    public let codeText: String

    public init(
        name: String,
        background: String,
        text: String,
        heading: String,
        accent: String,
        codeBackground: String,
        codeText: String
    ) {
        self.name = name
        self.background = background
        self.text = text
        self.heading = heading
        self.accent = accent
        self.codeBackground = codeBackground
        self.codeText = codeText
    }

    /// Parse a hex color string like "#ff0000" or "ff0000" to (r, g, b) in 0...1
    public static func parseHex(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt(h, radix: 16) else { return nil }
        return (
            r: Double((value >> 16) & 0xff) / 255.0,
            g: Double((value >> 8) & 0xff) / 255.0,
            b: Double(value & 0xff) / 255.0
        )
    }

    /// Whether the background color is dark (luminance < 0.5)
    public var isDark: Bool {
        guard let rgb = Self.parseHex(background) else { return true }
        let luminance = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
        return luminance < 0.5
    }
}
