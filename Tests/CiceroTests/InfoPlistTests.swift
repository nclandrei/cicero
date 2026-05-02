import Foundation
import Testing

// The app bundle's Info.plist is the source of macOS document-type associations.
// macOS only enables an app in "Open With…" dialogs (and only allows it as a
// default opener) when CFBundleDocumentTypes declares the file type. Without
// this, Cicero is greyed out for the very files it produces — `.md`.
//
// We keep Info.plist as a static, version-controlled file at the repo root so
// the release workflow consumes it verbatim (with placeholder substitution for
// version-bound fields) and tests can validate its structure.
@Suite("Info.plist")
struct InfoPlistTests {

    private static func loadInfoPlist() throws -> [String: Any] {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile
            .deletingLastPathComponent()  // CiceroTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // <repo root>
        let plistURL = repoRoot.appendingPathComponent("Info.plist")
        let data = try Data(contentsOf: plistURL)
        let parsed = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(parsed as? [String: Any])
    }

    @Test("Declares CFBundleDocumentTypes for markdown")
    func declaresMarkdownDocumentType() throws {
        let plist = try Self.loadInfoPlist()

        let documentTypes = try #require(
            plist["CFBundleDocumentTypes"] as? [[String: Any]],
            "Info.plist must define CFBundleDocumentTypes so macOS associates Cicero with file types"
        )

        let markdownEntry = documentTypes.first { entry in
            let extensions = entry["CFBundleTypeExtensions"] as? [String] ?? []
            return extensions.contains("md")
        }

        let entry = try #require(
            markdownEntry,
            "CFBundleDocumentTypes must include an entry with extension `md` so .md files map to Cicero"
        )

        let extensions = entry["CFBundleTypeExtensions"] as? [String] ?? []
        #expect(extensions.contains("md"))
        #expect(extensions.contains("markdown"))

        let role = entry["CFBundleTypeRole"] as? String
        #expect(
            role == "Editor",
            "Markdown role must be `Editor` so Cicero appears un-greyed in Open With and can be set as default"
        )
    }

    @Test("Declares the markdown UTI so Open With recognises .md files")
    func declaresMarkdownUTI() throws {
        let plist = try Self.loadInfoPlist()
        let documentTypes = try #require(plist["CFBundleDocumentTypes"] as? [[String: Any]])
        let markdownEntry = try #require(
            documentTypes.first { ($0["CFBundleTypeExtensions"] as? [String])?.contains("md") == true }
        )

        let contentTypes = markdownEntry["LSItemContentTypes"] as? [String] ?? []
        #expect(
            contentTypes.contains("net.daringfireball.markdown"),
            "Must declare net.daringfireball.markdown — the widely-used Markdown UTI — so the system links .md to Cicero"
        )
    }
}
