import Sparkle
import Combine

@MainActor
final class UpdaterController: ObservableObject {
    private var controller: SPUStandardUpdaterController?

    @Published var canCheckForUpdates = false
    @Published var lastUpdateCheckDate: Date?
    @Published var automaticallyChecksForUpdates: Bool = false {
        didSet {
            guard let updater = controller?.updater,
                  updater.automaticallyChecksForUpdates != automaticallyChecksForUpdates else { return }
            updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        }
    }
    @Published var automaticallyDownloadsUpdates: Bool = false {
        didSet {
            guard let updater = controller?.updater,
                  updater.automaticallyDownloadsUpdates != automaticallyDownloadsUpdates else { return }
            updater.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates
        }
    }

    /// True when Sparkle has a configured feed URL and the updater started successfully.
    /// False in unsigned/dev builds where there's no SUFeedURL in Info.plist.
    var isEnabled: Bool { controller != nil }

    init() {
        // Don't auto-start the updater — it fails in debug/unsigned builds.
        let c = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        // Only start if an appcast URL is configured (i.e. a release build).
        if c.updater.feedURL != nil {
            do {
                try c.updater.start()
                controller = c

                // Seed published properties from the updater's current state
                // before wiring observers, to avoid didSet round-tripping.
                automaticallyChecksForUpdates = c.updater.automaticallyChecksForUpdates
                automaticallyDownloadsUpdates = c.updater.automaticallyDownloadsUpdates
                lastUpdateCheckDate = c.updater.lastUpdateCheckDate

                c.updater.publisher(for: \.canCheckForUpdates)
                    .assign(to: &$canCheckForUpdates)
                c.updater.publisher(for: \.lastUpdateCheckDate)
                    .assign(to: &$lastUpdateCheckDate)
            } catch {
                // Updater can't start (unsigned/debug build) — silently disable.
                controller = nil
            }
        }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
