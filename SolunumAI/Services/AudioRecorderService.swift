import AVFoundation
import Combine
import Foundation

// MARK: - Recording State

enum RecordingState {
    case idle, recording, stopped, error(String)
}

// MARK: - AudioRecorderService

final class AudioRecorderService: NSObject, ObservableObject {

    // Recording state
    @Published var state: RecordingState = .idle
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var waveformSamples: [Float] = Array(repeating: 0, count: 50)
    @Published var qualityLabel: String = "—"
    @Published var isGoodQuality: Bool = false

    // Playback state
    @Published var isPlaying: Bool = false
    @Published var playbackTime: TimeInterval = 0

    // Trim state
    @Published var trimStart: TimeInterval = 0
    @Published var trimEnd: TimeInterval = 0   // set to min(recordedDuration, 10) on stop

    private(set) var recordedFileURL: URL?
    private(set) var recordedDuration: TimeInterval = 0

    let minDuration: TimeInterval = 2
    let maxDuration: TimeInterval = 10

    private var audioRecorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordTimer: Timer?
    private var levelTimer: Timer?
    private var playbackTimer: Timer?
    private var recordingStartTime: Date?

    // MARK: - URLs

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("solunumai_recording.wav")
    }

    private var trimmedURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("solunumai_trimmed.wav")
    }

    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey:             Int(kAudioFormatLinearPCM),
            AVSampleRateKey:           16000,
            AVNumberOfChannelsKey:     1,
            AVLinearPCMBitDepthKey:    16,
            AVLinearPCMIsFloatKey:     false,
            AVLinearPCMIsBigEndianKey: false,
        ]
    }

    // MARK: - Permissions

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        Task { @MainActor in
            let granted = await requestPermission()
            guard granted else {
                state = .error("Mikrofon izni gereklidir. Ayarlar > SolunumAI > Mikrofon'u etkinleştirin.")
                return
            }
            doStart()
        }
    }

    private func doStart() {
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            recordingStartTime = Date()
            duration = 0
            waveformSamples = Array(repeating: 0, count: 50)
            state = .recording
            recordedFileURL = nil

            startTimers()
        } catch {
            state = .error("Kayıt başlatılamadı: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard case .recording = state else { return }
        audioRecorder?.stop()
        stopTimers()

        let elapsed = Date().timeIntervalSince(recordingStartTime ?? Date())
        if elapsed < minDuration {
            state = .error("Kayıt çok kısa. En az \(Int(minDuration)) saniye öksürün.")
            try? FileManager.default.removeItem(at: recordingURL)
        } else {
            recordedDuration = elapsed
            trimStart = 0
            trimEnd = min(elapsed, maxDuration)
            recordedFileURL = recordingURL
            state = .stopped
            activatePlaybackSession()
        }
    }

    func reset() {
        stopTimers()
        stopPlayback()
        audioRecorder?.stop()
        audioRecorder = nil
        state = .idle
        duration = 0
        audioLevel = 0
        playbackTime = 0
        trimStart = 0
        trimEnd = 0
        recordedDuration = 0
        waveformSamples = Array(repeating: 0, count: 50)
        qualityLabel = "—"
        isGoodQuality = false
        recordedFileURL = nil
    }

    // MARK: - Timers (recording)

    private func startTimers() {
        recordTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.duration = Date().timeIntervalSince(self.recordingStartTime ?? Date())
            if self.duration >= self.maxDuration {
                self.stopRecording()
            }
        }
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateLevels()
        }
    }

    private func stopTimers() {
        recordTimer?.invalidate(); recordTimer = nil
        levelTimer?.invalidate(); levelTimer = nil
    }

    private func updateLevels() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let normalized = max(0, min(1, (power + 60) / 60))
        audioLevel = normalized

        var samples = waveformSamples
        samples.removeFirst()
        samples.append(normalized)
        waveformSamples = samples

        isGoodQuality = normalized > 0.15
        qualityLabel   = isGoodQuality ? "İyi Kalite" : "Zayıf Sinyal"
    }

    // MARK: - Playback

    private func activatePlaybackSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func togglePlayback() {
        if isPlaying { pausePlayback() } else { startPlayback() }
    }

    private func startPlayback() {
        guard let url = recordedFileURL else { return }
        activatePlaybackSession()

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.currentTime = playbackTime
            player?.play()
            isPlaying = true

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self, let p = self.player else { return }
                self.playbackTime = p.currentTime
                // Stop at trimEnd
                if p.currentTime >= self.trimEnd {
                    self.pausePlayback()
                    self.playbackTime = self.trimStart
                    self.player?.currentTime = self.trimStart
                }
            }
        } catch {
            state = .error("Ses oynatılamadı: \(error.localizedDescription)")
        }
    }

    func pausePlayback() {
        player?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func seek(to time: TimeInterval) {
        playbackTime = time
        player?.currentTime = time
    }

    // MARK: - Trim export

    /// Returns a WAV URL containing only the [trimStart, trimEnd] region.
    /// If no trim is applied, returns the original file directly to avoid re-encoding quality loss.
    func trimmedAudioURL() -> URL? {
        guard let sourceURL = recordedFileURL else { return nil }

        // No actual trim → send original to preserve audio quality for the model
        let trimApplied = trimStart > 0.05 || (recordedDuration - trimEnd) > 0.05
        if !trimApplied { return sourceURL }

        let sr: Double = 16000
        let startFrame = AVAudioFramePosition(trimStart * sr)
        let frameCount = AVAudioFrameCount((trimEnd - trimStart) * sr)
        guard frameCount > 0 else { return nil }

        do {
            let sourceFile = try AVAudioFile(forReading: sourceURL)
            // AVAudioFile always processes as float32 — match its processingFormat
            let readFormat = sourceFile.processingFormat
            guard let buffer = AVAudioPCMBuffer(pcmFormat: readFormat, frameCapacity: frameCount) else {
                return sourceURL
            }
            sourceFile.framePosition = startFrame
            try sourceFile.read(into: buffer, frameCount: frameCount)

            try? FileManager.default.removeItem(at: trimmedURL)
            let outFile = try AVAudioFile(forWriting: trimmedURL, settings: [
                AVFormatIDKey:             Int(kAudioFormatLinearPCM),
                AVSampleRateKey:           sr,
                AVNumberOfChannelsKey:     1,
                AVLinearPCMBitDepthKey:    16,
                AVLinearPCMIsFloatKey:     false,
                AVLinearPCMIsBigEndianKey: false,
            ])
            try outFile.write(from: buffer)
            return trimmedURL
        } catch {
            return sourceURL  // fallback: send full recording
        }
    }

    // MARK: - File import

    func importAudioFile(from url: URL) {
        stopPlayback()
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("solunumai_import.\(url.pathExtension)")
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
            recordedFileURL = dest

            // Read duration
            // Read duration from imported file
            if let avPlayer = try? AVAudioPlayer(contentsOf: dest) {
                recordedDuration = avPlayer.duration
            } else {
                recordedDuration = 10
            }
            trimStart = 0
            trimEnd = Swift.min(recordedDuration, maxDuration)
            playbackTime = 0
            state = .stopped
            activatePlaybackSession()
        } catch {
            state = .error("Dosya içe aktarılamadı: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.state = .error("Kayıt tamamlanamadı. Lütfen tekrar deneyin.")
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.playbackTime = self.trimStart
            self.player?.currentTime = self.trimStart
            self.playbackTimer?.invalidate()
            self.playbackTimer = nil
        }
    }
}
