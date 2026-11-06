import AVFoundation
import Combine
import Foundation

@MainActor
final class PracticeSynth {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0

    init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        if let format {
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(midiPitch: Int) {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let duration = 0.42
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = frameCount
        let frequency = 440.0 * pow(2.0, Double(midiPitch - 69) / 12.0)
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let attack = min(1.0, time / 0.015)
            let release = min(1.0, (duration - time) / 0.08)
            samples[frame] = Float(sin(2.0 * .pi * frequency * time) * 0.18 * attack * release)
        }

        if !engine.isRunning {
            try? engine.start()
        }
        player.scheduleBuffer(buffer)
        if !player.isPlaying {
            player.play()
        }
    }

    func stop() {
        player.stop()
        engine.stop()
    }

    deinit {
        player.stop()
        engine.stop()
    }
}

@MainActor
final class PlaybackController: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var activeMeasure = 0
    @Published private(set) var activeBeat = 0

    private var timer: Timer?
    private let synth = PracticeSynth()

    func toggle(song: TGSong, track: TGTrack) {
        isPlaying ? stop() : start(song: song, track: track)
    }

    func start(song: TGSong, track: TGTrack) {
        guard !track.measures.isEmpty else { return }
        timer?.invalidate()
        activeMeasure = min(activeMeasure, track.measures.count - 1)
        activeBeat = 0
        isPlaying = true
        playCurrentBeat(in: track)

        let interval = 60.0 / Double(max(song.tempo, 40))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advance(in: track)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        synth.stop()
    }

    func jump(to measure: Int) {
        activeMeasure = max(0, measure)
        activeBeat = 0
    }

    private func advance(in track: TGTrack) {
        guard isPlaying else { return }
        activeBeat += 1
        if activeMeasure >= track.measures.count {
            stop()
            return
        }
        if activeBeat >= track.measures[activeMeasure].beats.count {
            activeBeat = 0
            activeMeasure += 1
        }
        guard activeMeasure < track.measures.count else {
            stop()
            return
        }
        playCurrentBeat(in: track)
    }

    private func playCurrentBeat(in track: TGTrack) {
        guard track.measures.indices.contains(activeMeasure),
              track.measures[activeMeasure].beats.indices.contains(activeBeat) else { return }
        for note in track.measures[activeMeasure].beats[activeBeat].notes {
            synth.play(midiPitch: note.midiPitch)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
