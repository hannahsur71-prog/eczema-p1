import AVFoundation

/// Steady white or pink noise, generated in real time (no audio files needed).
final class NoiseEngine {
    enum Kind: String {
        case white = "White noise"
        case pink = "Pink noise"
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private(set) var kind: Kind?

    // Pink-noise filter state (touched on the audio thread).
    private var b0 = 0.0, b1 = 0.0, b2 = 0.0
    private var isPink = false

    func start(_ kind: Kind, volume: Float = 0.08) {
        stop()
        isPink = kind == .pink
        let output = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = output.sampleRate > 0 ? output.sampleRate : 44_100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let node = AVAudioSourceNode(format: format) { [unowned self] _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for frame in 0..<Int(frameCount) {
                let white = Double.random(in: -1...1)
                var sample = white
                if self.isPink {
                    // Paul Kellet's economy pink filter.
                    self.b0 = 0.99765 * self.b0 + white * 0.0990460
                    self.b1 = 0.96300 * self.b1 + white * 0.2965164
                    self.b2 = 0.57000 * self.b2 + white * 1.0526913
                    sample = (self.b0 + self.b1 + self.b2 + white * 0.1848) * 0.25
                }
                let value = Float(sample) * volume
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
            self.kind = kind
        } catch {
            engine.detach(node)
            sourceNode = nil
        }
    }

    func stop() {
        guard let node = sourceNode else { return }
        engine.stop()
        engine.detach(node)
        sourceNode = nil
        kind = nil
    }
}
