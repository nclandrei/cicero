import Foundation

/// 2D point used by SlideDrawingStroke. Encoded as `{"x": Double, "y": Double}`
/// since CGPoint is not Codable on Linux/Foundation.
public struct SlideDrawingPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A persisted drawing stroke captured during a presentation. The UI layer
/// (Cicero target) has its own `DrawingStroke` type with a SwiftUI Color,
/// which is not Codable; this type mirrors it with a hex color string and
/// Codable points so it can round-trip through markdown frontmatter.
public struct SlideDrawingStroke: Codable, Equatable, Sendable {
    public var points: [SlideDrawingPoint]
    /// Hex color string, e.g. "#ff0000". Optional alpha as 8-digit hex.
    public var color: String

    public init(points: [SlideDrawingPoint] = [], color: String = "#ff0000") {
        self.points = points
        self.color = color
    }
}

/// Encode/decode helpers for the `drawings: <base64-json>` slide frontmatter line.
public enum SlideDrawingCodec {
    /// Encode strokes as a base64-encoded JSON array, suitable for a single-line
    /// frontmatter value. Returns nil for empty/nil arrays.
    public static func encode(_ strokes: [SlideDrawingStroke]?) -> String? {
        guard let strokes, !strokes.isEmpty else { return nil }
        guard let data = try? JSONEncoder().encode(strokes) else { return nil }
        return data.base64EncodedString()
    }

    /// Decode a base64-encoded JSON string into strokes. Returns nil on any
    /// malformed input — callers should treat that as "no drawings".
    public static func decode(_ base64: String) -> [SlideDrawingStroke]? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode([SlideDrawingStroke].self, from: data)
    }
}
