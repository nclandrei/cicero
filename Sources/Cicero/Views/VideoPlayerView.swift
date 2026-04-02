import SwiftUI
import AVKit
import Shared

// MARK: - Full-Slide Video Layout

/// Full-slide layout that plays a video with optional text overlay from the slide body.
struct VideoLayoutView: View {
    let content: String
    let videoURL: String?
    let theme: SlideTheme
    var baseDirectory: URL?

    var body: some View {
        ZStack {
            if let resolvedURL = resolveVideoURL() {
                VideoPlayer(player: AVPlayer(url: resolvedURL))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                videoPlaceholder
            }

            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack {
                    Spacer()
                    Text(content)
                        .font(.title2)
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var videoPlaceholder: some View {
        ZStack {
            theme.codeBackground
            VStack(spacing: 12) {
                Image(systemName: "play.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.text.opacity(0.3))
                Text(videoURL ?? "No video URL")
                    .font(.caption)
                    .foregroundStyle(theme.text.opacity(0.5))
            }
        }
    }

    private func resolveVideoURL() -> URL? {
        guard let urlString = videoURL, !urlString.isEmpty else { return nil }

        // Absolute URL
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        }

        // Local file — resolve relative to base directory or as absolute path
        if let baseDirectory {
            let fileURL = baseDirectory.appendingPathComponent(urlString)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }

        let absoluteURL = URL(fileURLWithPath: urlString)
        if FileManager.default.fileExists(atPath: absoluteURL.path) {
            return absoluteURL
        }

        return nil
    }
}

// MARK: - Inline Video Player

/// Inline video player for use within markdown content via `![video](path.mp4)`.
struct InlineVideoPlayerView: View {
    let url: URL?
    let baseDirectory: URL?

    var body: some View {
        if let resolvedURL = resolveURL() {
            VideoPlayer(player: AVPlayer(url: resolvedURL))
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .cornerRadius(8)
        } else {
            Text("Video not found")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func resolveURL() -> URL? {
        guard let url else { return nil }

        if url.scheme == "http" || url.scheme == "https" {
            return url
        }

        // Local file resolution
        let path = url.path
        if let baseDirectory {
            let relativePath = url.relativePath.isEmpty ? path : url.relativePath
            let fileURL = baseDirectory.appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }

        let absoluteURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: absoluteURL.path) {
            return absoluteURL
        }

        return nil
    }
}
