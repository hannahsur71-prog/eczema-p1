import AVFoundation
import Observation
import UIKit

/// Runs tonight's ritual: timed massage steps with voice cues and ambient music,
/// then reads the story aloud and fades the music out.
@MainActor
@Observable
final class RitualEngine {
    enum Phase { case massage, story, finished }

    let steps: [RitualStep]
    let story: Story
    private(set) var phase: Phase = .massage
    private(set) var index = 0
    private(set) var remaining = 0
    private(set) var isPlaying = false
    var voiceOn = true { didSet { if !voiceOn { speech.stop() } } }
    var musicOn = true { didSet { musicOn ? ambient.start() : ambient.stop() } }

    let stepSeconds: Int
    private var tickTask: Task<Void, Never>?
    private let ambient = AmbientSoundEngine()
    private let speech = SpeechCoordinator()

    /// When false (the onboarding taste), the ritual ends after the massage steps.
    let includesStory: Bool

    init(steps: [RitualStep], story: Story, minutes: Int, includesStory: Bool = true, stepSecondsOverride: Int? = nil) {
        self.steps = steps
        self.story = story
        self.includesStory = includesStory
        self.stepSeconds = stepSecondsOverride ?? max(20, (minutes * 60) / max(steps.count, 1))
        self.remaining = stepSeconds
    }

    var currentStep: RitualStep { steps[min(index, steps.count - 1)] }
    var stepFraction: Double { 1 - Double(remaining) / Double(max(stepSeconds, 1)) }

    func start() {
        configureAudioSession()
        UIApplication.shared.isIdleTimerDisabled = true
        if musicOn { ambient.start() }
        isPlaying = true
        speakCurrentStep()
        startTicking()
    }

    func togglePause() {
        isPlaying.toggle()
        isPlaying ? speech.resume() : speech.pause()
    }

    func nextStep() {
        guard phase == .massage else { return }
        if index + 1 < steps.count {
            index += 1
            remaining = stepSeconds
            speakCurrentStep()
        } else {
            beginStory()
        }
    }

    /// Ends everything immediately (e.g. the parent taps End).
    func stop() {
        tickTask?.cancel()
        speech.stop()
        ambient.fadeOut(over: 2)
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .finished
        isPlaying = false
    }

    // MARK: Private

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isPlaying, phase == .massage else { return }
        if remaining > 1 {
            remaining -= 1
        } else {
            nextStep()
        }
    }

    private func speakCurrentStep() {
        guard voiceOn else { return }
        speech.speak([currentStep.narration], rate: 0.42, onFinish: nil)
    }

    private func beginStory() {
        tickTask?.cancel()
        guard includesStory else {
            phase = .finished
            isPlaying = false
            UIApplication.shared.isIdleTimerDisabled = false
            ambient.fadeOut(over: 4)
            return
        }
        phase = .story
        UIApplication.shared.isIdleTimerDisabled = false
        let lines = [story.title + "."] + story.paragraphs
        speech.speak(lines, rate: 0.40) { [weak self] in
            Task { @MainActor in self?.finishStory() }
        }
    }

    private func finishStory() {
        guard phase == .story else { return }
        phase = .finished
        isPlaying = false
        // Music keeps playing softly, then fades over two minutes.
        ambient.fadeOut(over: 120)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [])
        try? session.setActive(true)
    }
}

/// Wraps AVSpeechSynthesizer and reports when a queue of lines has been spoken.
final class SpeechCoordinator: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var pendingUtterances = 0
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ lines: [String], rate: Float, onFinish: (() -> Void)?) {
        synthesizer.stopSpeaking(at: .immediate)
        self.onFinish = onFinish
        pendingUtterances = lines.count
        let voice = AVSpeechSynthesisVoice(language: "en-US")
        for line in lines {
            let utterance = AVSpeechUtterance(string: line)
            utterance.voice = voice
            utterance.rate = rate
            utterance.pitchMultiplier = 0.95
            utterance.postUtteranceDelay = 0.8
            synthesizer.speak(utterance)
        }
    }

    func pause() { synthesizer.pauseSpeaking(at: .word) }
    func resume() { synthesizer.continueSpeaking() }

    func stop() {
        onFinish = nil
        pendingUtterances = 0
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        pendingUtterances -= 1
        if pendingUtterances <= 0, let callback = onFinish {
            onFinish = nil
            DispatchQueue.main.async { callback() }
        }
    }
}
