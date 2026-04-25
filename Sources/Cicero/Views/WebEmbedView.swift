import SwiftUI
import WebKit
import MarkdownUI
import Splash
import Shared

// MARK: - Full-Slide Embed Layout

/// Full-slide layout that displays a web page via WKWebView.
struct EmbedLayoutView: View {
    let content: String
    let embedURL: String?
    let theme: SlideTheme
    var fontFamily: String? = nil

    var body: some View {
        ZStack {
            if let url = resolveEmbedURL(embedURL) {
                WebEmbedRepresentable(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                embedPlaceholder
            }

            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack {
                    Spacer()
                    Markdown(content)
                        .markdownTheme(theme.markdownTheme(fontFamily: fontFamily))
                        .markdownCodeSyntaxHighlighter(.splash(theme: theme.splashTheme))
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

    private var embedPlaceholder: some View {
        ZStack {
            theme.codeBackground
            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.text.opacity(0.3))
                Text(embedURL ?? "No embed URL")
                    .font(.caption)
                    .foregroundStyle(theme.text.opacity(0.5))
            }
        }
    }
}

// MARK: - Inline Web Embed

/// Inline web embed for use within markdown content via `![embed](url)`.
struct InlineWebEmbedView: View {
    let url: URL?

    var body: some View {
        if let resolved = resolveInlineURL() {
            WebEmbedRepresentable(url: resolved)
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .cornerRadius(8)
        } else {
            Text("Embed not available")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func resolveInlineURL() -> URL? {
        guard let url else { return nil }
        // Strip the #embed fragment to get the real URL
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.fragment = nil
        guard let cleanURL = components?.url else { return url }
        return normalizeYouTubeURL(cleanURL)
    }
}

// MARK: - NSViewRepresentable for WKWebView

struct WebEmbedRepresentable: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

// MARK: - YouTube URL Helpers

/// Normalize a YouTube watch URL to an embed URL.
/// `https://www.youtube.com/watch?v=ID` → `https://www.youtube.com/embed/ID`
/// `https://youtu.be/ID` → `https://www.youtube.com/embed/ID`
/// Already-embed URLs and non-YouTube URLs pass through unchanged.
func normalizeYouTubeURL(_ url: URL) -> URL {
    let host = url.host?.lowercased() ?? ""

    // youtu.be/ID shortlinks
    if host == "youtu.be" {
        let videoID = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !videoID.isEmpty {
            return URL(string: "https://www.youtube.com/embed/\(videoID)") ?? url
        }
    }

    // youtube.com/watch?v=ID
    if (host == "www.youtube.com" || host == "youtube.com"),
       url.path == "/watch",
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value
    {
        return URL(string: "https://www.youtube.com/embed/\(videoID)") ?? url
    }

    return url
}

/// Resolve an embed URL string, normalizing YouTube watch links.
func resolveEmbedURL(_ urlString: String?) -> URL? {
    guard let urlString, !urlString.isEmpty,
          let url = URL(string: urlString) else { return nil }
    return normalizeYouTubeURL(url)
}
