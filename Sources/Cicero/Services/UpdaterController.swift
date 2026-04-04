import Sparkle

@MainActor
final class UpdaterController: ObservableObject {
    private var controller: SPUStandardUpdaterController?

    @Published var canCheckForUpdates = false

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
                c.updater.publisher(for: \.canCheckForUpdates)
                    .assign(to: &$canCheckForUpdates)
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
