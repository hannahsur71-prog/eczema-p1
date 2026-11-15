import AVFoundation

/// Reads stories aloud in a slow, gentle voice.
/// TODO before launch: replace the built-in voice with recorded narration.
final class Narrator: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks `text`. `onFinish` runs only if the text was read to the end, not if it was stopped.
    func speak(_ text: String, volume: Float = 0.9, onFinish: (() -> Void)? = nil) {
        stop()
        self.onFinish = onFinish
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.82
        utterance.volume = volume
        utterance.postUtteranceDelay = 0.6
        synthesizer.speak(utterance)
    }

    func stop() {
        onFinish = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let done = onFinish
        onFinish = nil
        DispatchQueue.main.async { done?() }
    }
}
