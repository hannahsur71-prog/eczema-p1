import SwiftUI
import AVFoundation
import Observation

/// A full-screen page shown over the tabs.
enum MainScreen: Equatable {
    case detail(String)
    case ready
    case player(storyID: String, isFlare: Bool, greets: Bool)
    case end(storyID: String, minutes: Int, isFlare: Bool)
    case dark
    case audio(String)
    case create
    case creating
}

enum TonightPanel {
    case skin, plan
}

/// Which page is open, plus the app's one voice and one music player.
@MainActor
@Observable
final class MainRouter {
    var screen: MainScreen?
    /// A panel rising over the tabs.
    var panel: TonightPanel?
    var showsUpgrade = false

    @ObservationIgnored let narrator = Narrator()
    @ObservationIgnored let music = AmbientSoundEngine()
    @ObservationIgnored let noise = NoiseEngine()

    init() {
        // Stories keep playing with the ringer off and the screen locked.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
    }

    func open(_ screen: MainScreen) {
        panel = nil
        self.screen = screen
    }

    /// Opens a story, or the upgrade offer if it isn't in the free version.
    func openStory(_ id: String, isSubscribed: Bool) {
        if isSubscribed || StoryCatalog.freeIDs.contains(id) {
            open(.detail(id))
        } else {
            showsUpgrade = true
        }
    }

    /// Stops all sound and returns to the tabs.
    func close() {
        quiet()
        screen = nil
    }

    func quiet() {
        narrator.stop()
        music.fadeOut(over: 1.5)
        noise.stop()
    }

    func startMusic(_ isOn: Bool, volume: Float = 0.12) {
        guard isOn else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        music.start(volume: volume, fadeSeconds: 4)
    }
}

extension StoryCatalog {
    /// What the free version includes. Everything else needs a subscription.
    static let freeIDs: Set<String> = ["comet", "flareStory", "sleepy", "loved", "breathe"]
}
