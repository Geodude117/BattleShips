import AVFoundation

/// The game's sound effects. Files live in BattleMaths/Sounds as `<name>.m4a`.
/// All sounds are CC0 by Kenney (see docs/CREDITS.md).
enum Sound: String, CaseIterable {
    case fire, hit, miss, sink
    case correct, wrong, special
    case place, sonar
    case win, lose
}

/// Plays short sound effects. Uses the "ambient" audio session, so sounds respect the
/// silent switch and mix with the player's own music instead of stopping it.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()
    static let enabledKey = "soundEnabled"

    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[sound] = player
        }
    }

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func play(_ sound: Sound) {
        guard isEnabled, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }

    /// Plays a sound after a short pause, e.g. the impact after the firing sound.
    func play(_ sound: Sound, after delay: Duration) {
        Task {
            try? await Task.sleep(for: delay)
            play(sound)
        }
    }

    /// Whether every sound file was found in the app bundle.
    var allSoundsLoaded: Bool {
        players.count == Sound.allCases.count
    }
}
