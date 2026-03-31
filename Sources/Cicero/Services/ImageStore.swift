import Foundation
import UniformTypeIdentifiers

final class ImageStore {
    private let assetsDirectory: URL

    init(baseURL: URL) {
        self.assetsDirectory = baseURL.deletingLastPathComponent().appendingPathComponent("assets")
    }

    /// Stores image data and returns the relative path (e.g., "assets/image-1.png")
    func storeImage(_ data: Data, suggestedName: String? = nil) -> String? {
        ensureAssetsDirectory()

        let ext = detectExtension(from: data)
        let baseName = suggestedName.map { sanitizeFilename($0) } ?? "image"
        let filename = uniqueFilename(base: baseName, ext: ext)

        let fileURL = assetsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return "assets/\(filename)"
        } catch {
            print("[ImageStore] Failed to write image: \(error)")
            return nil
        }
    }

    /// Resolves a relative path like "assets/img.png" to an absolute file URL
    func resolveImagePath(_ relativePath: String) -> URL? {
        let url = assetsDirectory.deletingLastPathComponent().appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Private

    private func ensureAssetsDirectory() {
        try? FileManager.default.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
    }

    private func detectExtension(from data: Data) -> String {
        guard data.count >= 4 else { return "png" }
        let header = [UInt8](data.prefix(4))

        // PNG: 89 50 4E 47
        if header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 {
            return "png"
        }
        // JPEG: FF D8 FF
        if header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF {
            return "jpg"
        }
        // GIF: 47 49 46
        if header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46 {
            return "gif"
        }
        // TIFF: 49 49 or 4D 4D
        if (header[0] == 0x49 && header[1] == 0x49) || (header[0] == 0x4D && header[1] == 0x4D) {
            return "tiff"
        }
        return "png"
    }

    private func sanitizeFilename(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted)
            .joined()
        // Strip any extension the user may have included
        if let dotIndex = cleaned.lastIndex(of: ".") {
            return String(cleaned[cleaned.startIndex..<dotIndex])
        }
        return cleaned.isEmpty ? "image" : cleaned
    }

    private func uniqueFilename(base: String, ext: String) -> String {
        let candidate = "\(base).\(ext)"
        let candidateURL = assetsDirectory.appendingPathComponent(candidate)
        if !FileManager.default.fileExists(atPath: candidateURL.path) {
            return candidate
        }
        // Append incrementing number
        for i in 1...999 {
            let numbered = "\(base)-\(i).\(ext)"
            let url = assetsDirectory.appendingPathComponent(numbered)
            if !FileManager.default.fileExists(atPath: url.path) {
                return numbered
            }
        }
        return "\(base)-\(UUID().uuidString.prefix(8)).\(ext)"
    }
}
