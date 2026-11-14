import AVFoundation

/// Generates a soft, spa-style ambient pad in real time (no audio files needed).
/// TODO before launch: swap for licensed, professionally produced spa music tracks.
final class AmbientSoundEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    // Render state (touched on the audio thread).
    private var phases: [Double] = [0, 0, 0, 0, 0]
    private let frequencies: [Double] = [130.81, 196.00, 261.63, 329.63, 392.00] // C major, open voicing
    private var swellPhase: Double = 0
    private var gain: Float = 0
    private var targetGain: Float = 0
    private var gainRate: Float = 0.00001

    private(set) var isRunning = false

    func start(volume: Float = 0.12, fadeSeconds: Double = 3) {
        if !isRunning {
            let output = engine.outputNode.outputFormat(forBus: 0)
            let sampleRate = output.sampleRate > 0 ? output.sampleRate : 44_100
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

            let node = AVAudioSourceNode(format: format) { [unowned self] _, _, frameCount, bufferList -> OSStatus in
                let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
                for frame in 0..<Int(frameCount) {
                    self.gain += (self.targetGain - self.gain) * self.gainRate
                    var sample = 0.0
                    for index in 0..<self.frequencies.count {
                        sample += sin(self.phases[index]) * (0.22 / Double(index + 1))
                        self.phases[index] += 2 * .pi * self.frequencies[index] / sampleRate
                        if self.phases[index] > 2 * .pi { self.phases[index] -= 2 * .pi }
                    }
                    self.swellPhase += 2 * .pi * 0.06 / sampleRate
                    if self.swellPhase > 2 * .pi { self.swellPhase -= 2 * .pi }
                    let swell = 0.7 + 0.3 * sin(self.swellPhase)
                    let value = Float(sample * swell) * self.gain
                    for buffer in buffers {
                        let pointer = UnsafeMutableBufferPointer<Float>(buffer)
                        if frame < pointer.count { pointer[frame] = value }
                    }
                }
                return noErr
            }
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            sourceNode = node
            do {
                try engine.start()
                isRunning = true
            } catch {
                return
            }
        }
        setGain(volume, over: fadeSeconds)
    }

    /// Fades to silence, then stops the engine.
    func fadeOut(over seconds: Double) {
        guard isRunning else { return }
        setGain(0, over: seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds + 0.5) { [weak self] in
            guard let self, self.targetGain == 0 else { return }
            self.stop()
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        if let node = sourceNode {
            engine.detach(node)
        }
        sourceNode = nil
        isRunning = false
        gain = 0
    }

    private func setGain(_ value: Float, over seconds: Double) {
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let frames = max(1, Float(seconds * (sampleRate > 0 ? sampleRate : 44_100)))
        // Exponential approach reaching ~99% of the target after `seconds`.
        gainRate = min(1, 4.6 / frames)
        targetGain = value
    }
}
