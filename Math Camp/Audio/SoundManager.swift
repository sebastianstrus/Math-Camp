//
//  SoundManager.swift
//  Math Camp
//

import AVFoundation

/// Every sound effect the app can play. The raw value is the file name (without extension)
/// that has to be in the app bundle: `.caf`, `.wav`, `.m4a` or `.mp3`.
enum SoundEffect: String, CaseIterable {
    /// A key of the numeric keypad.
    case keyTap = "key_tap"
    /// The "Check" button.
    case check = "check"
    /// A star popping in on the results card. One file, pitched up for each star (see `playStar`).
    case star = "star"
    /// Fanfare after the third star.
    case taskPerfect = "task_perfect"
    /// Gentle, encouraging sound when no star was earned.
    case taskRetry = "task_retry"

    /// How many players are kept ready, so quick repeats (typing) can overlap.
    fileprivate var voices: Int {
        switch self {
        case .keyTap: 3
        default: 1
        }
    }

    fileprivate var volume: Float {
        switch self {
        case .keyTap: 0.6
        default: 1
        }
    }
}

/// Plays short sound effects. Respects the sound toggle in Settings and the silent switch
/// (`.ambient`), and mixes with music the child may already be playing.
/// A missing file is skipped silently, so the app works before all sounds are added.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    /// The `@AppStorage` key used by the toggle in Settings.
    static let enabledKey = "soundEnabled"

    /// A sound played through the engine at a shifted pitch.
    private struct PitchedVoice {
        let node: AVAudioPlayerNode
        let pitch: AVAudioUnitTimePitch
    }

    private struct VoiceKey: Hashable {
        let effect: SoundEffect
        let cents: Int
    }

    /// Pitch of the 1st, 2nd and 3rd star in cents: a rising major chord (do, mi, sol).
    private static let starPitches: [Float] = [0, 400, 700]

    private var pool: [SoundEffect: [AVAudioPlayer]] = [:]
    private var isSessionConfigured = false
    private var sessionTask: Task<Void, Never>?

    private let engine = AVAudioEngine()
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var pitchedVoices: [VoiceKey: PitchedVoice] = [:]

    private static let fileExtensions = ["caf", "wav", "m4a", "mp3"]

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Loads the sounds ahead of time so the first tap has no delay. Call once at launch.
    func prepare() {
        configureSession()
        Task {
            // Players would activate the session on the main thread if it isn't active yet.
            await sessionTask?.value
            for effect in SoundEffect.allCases where effect != .star { _ = players(for: effect) }
            _ = buffer(for: .star)
        }
    }

    /// Plays the star sound for the 1st, 2nd or 3rd star, each one higher than the last.
    func playStar(_ number: Int) {
        guard (1...Self.starPitches.count).contains(number) else { return }
        play(.star, pitchCents: Self.starPitches[number - 1])
    }

    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        configureSession()
        let players = players(for: effect)
        // A free voice, or the oldest one restarted when all are busy.
        guard let player = players.first(where: { !$0.isPlaying }) ?? players.first else { return }
        player.currentTime = 0
        player.play()
    }

    /// Plays `effect` shifted by `pitchCents` (100 cents = one semitone) without changing its length.
    func play(_ effect: SoundEffect, pitchCents: Float) {
        guard isEnabled else { return }
        configureSession()
        guard let buffer = buffer(for: effect),
              let voice = voice(for: effect, cents: pitchCents, format: buffer.format) else { return }

        if !engine.isRunning {
            engine.prepare()
            do { try engine.start() } catch { return }
        }
        voice.node.volume = effect.volume
        voice.node.stop()
        voice.node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        voice.node.play()
    }

    // MARK: Private

    private static func url(for effect: SoundEffect) -> URL? {
        fileExtensions.lazy
            .compactMap { Bundle.main.url(forResource: effect.rawValue, withExtension: $0) }.first
    }

    private func buffer(for effect: SoundEffect) -> AVAudioPCMBuffer? {
        if let cached = buffers[effect] { return cached }
        guard let url = Self.url(for: effect) else {
            #if DEBUG
            print("SoundManager: missing sound file \"\(effect.rawValue)\"")
            #endif
            return nil
        }
        guard let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil else { return nil }
        buffers[effect] = buffer
        return buffer
    }

    /// One player node per effect and pitch, wired once into the engine.
    private func voice(for effect: SoundEffect, cents: Float, format: AVAudioFormat) -> PitchedVoice? {
        let key = VoiceKey(effect: effect, cents: Int(cents))
        if let existing = pitchedVoices[key] { return existing }

        let node = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = cents
        engine.attach(node)
        engine.attach(pitch)
        engine.connect(node, to: pitch, format: format)
        engine.connect(pitch, to: engine.mainMixerNode, format: format)

        let voice = PitchedVoice(node: node, pitch: pitch)
        pitchedVoices[key] = voice
        return voice
    }

    private func configureSession() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true
        // Category and activation can block, so keep them off the main thread.
        sessionTask = Task.detached(priority: .userInitiated) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default)
                try session.setActive(true)
            } catch {
                #if DEBUG
                print("SoundManager: audio session failed: \(error)")
                #endif
            }
        }
    }

    private func players(for effect: SoundEffect) -> [AVAudioPlayer] {
        if let cached = pool[effect] { return cached }

        var players: [AVAudioPlayer] = []
        if let url = Self.url(for: effect) {
            for _ in 0..<effect.voices {
                guard let player = try? AVAudioPlayer(contentsOf: url) else { break }
                player.volume = effect.volume
                player.prepareToPlay()
                players.append(player)
            }
        } else {
            #if DEBUG
            print("SoundManager: missing sound file \"\(effect.rawValue)\"")
            #endif
        }
        pool[effect] = players
        return players
    }
}
