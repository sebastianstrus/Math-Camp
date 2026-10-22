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
    /// The first, second and third star popping in on the results card.
    case star1 = "star_1"
    case star2 = "star_2"
    case star3 = "star_3"
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

    static func star(_ number: Int) -> SoundEffect? {
        switch number {
        case 1: .star1
        case 2: .star2
        case 3: .star3
        default: nil
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

    private var pool: [SoundEffect: [AVAudioPlayer]] = [:]
    private var isSessionConfigured = false

    private static let fileExtensions = ["caf", "wav", "m4a", "mp3"]

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Loads the sounds ahead of time so the first tap has no delay. Call once at launch.
    func prepare() {
        configureSession()
        for effect in SoundEffect.allCases { _ = players(for: effect) }
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

    // MARK: Private

    private func configureSession() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("SoundManager: audio session failed: \(error)")
            #endif
        }
    }

    private func players(for effect: SoundEffect) -> [AVAudioPlayer] {
        if let cached = pool[effect] { return cached }

        var players: [AVAudioPlayer] = []
        if let url = Self.fileExtensions.lazy
            .compactMap({ Bundle.main.url(forResource: effect.rawValue, withExtension: $0) }).first {
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
