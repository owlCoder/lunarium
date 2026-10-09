import AppKit
import Sparkle

/// Sparkle is dormant in unsigned local builds without a trusted EdDSA public
/// key + HTTPS appcast. Release automation injects these into Info.plist *before*
/// signing. No unsigned or unverified binary is automatically installed.
@MainActor
final class UpdateCoordinator {
    private var controller: SPUStandardUpdaterController?

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
        if !key.isEmpty, let url = URL(string: feed), url.scheme == "https" {
            controller = SPUStandardUpdaterController(
                startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
            )
        }
    }

    func checkForUpdates() {
        if let controller {
            controller.checkForUpdates(nil)
        } else if let url = URL(string: "https://github.com/owlCoder/lunarium/releases") {
            NSWorkspace.shared.open(url)
        }
    }
}
