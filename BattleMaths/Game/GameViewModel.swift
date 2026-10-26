import Foundation
import Observation
import BattleEngine

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: Self { self }
    var title: String { rawValue.capitalized }

    /// How often the computer "answers its question" correctly and gets to fire.
    var accuracy: Double {
        switch self {
        case .easy: 0.6
        case .medium: 0.75
        case .hard: 0.9
        }
    }

    var strategy: AIStrategy {
        self == .easy ? .random : .huntTarget
    }
}

enum Phase: Equatable {
    case playerTurn
    case enemyTurn
    case won
    case lost
}

struct AnswerFeedback: Equatable {
    let chosenIndex: Int
    let isCorrect: Bool
    let ammoEarned: Int
}

/// Runs one game: answer a question to load ammo, fire until it runs out, then the enemy takes a turn.
@MainActor
@Observable
final class GameViewModel {
    private(set) var playerBoard = Board()
    private(set) var enemyBoard = Board()
    private(set) var ledger = AmmoLedger()
    private(set) var phase: Phase = .playerTurn
    private(set) var feedback: AnswerFeedback?
    private(set) var log: [String] = []
    private(set) var questionsAnswered = 0
    private(set) var questionsCorrect = 0
    var question: Question?
    var difficulty: Difficulty = .medium {
        didSet {
            if difficulty != oldValue { addLog("Difficulty set to \(difficulty.title).") }
        }
    }

    @ObservationIgnored private var rng = SeededGenerator(seed: 0)
    /// Bumped on every new game so an enemy turn scheduled in an old game never fires in a new one.
    @ObservationIgnored private var gameID = 0

    init() {
        newGame()
    }

    var ammo: Int { ledger.ammo }
    var canFire: Bool { phase == .playerTurn && ledger.ammo > 0 }
    var canAsk: Bool { phase == .playerTurn && ledger.ammo == 0 && question == nil }
    var isGameOver: Bool { phase == .won || phase == .lost }

    func newGame() {
        gameID += 1
        rng = SeededGenerator(seed: UInt64.random(in: 0...UInt64.max))
        playerBoard = Board.randomFleet(using: &rng)
        enemyBoard = Board.randomFleet(using: &rng)
        ledger = AmmoLedger()
        phase = .playerTurn
        question = nil
        feedback = nil
        questionsAnswered = 0
        questionsCorrect = 0
        log = []
        addLog("New game on \(difficulty.title). Answer a question to load your guns.")
    }

    // MARK: Questions

    func askQuestion() {
        guard canAsk else { return }
        feedback = nil
        question = QuestionBank.random(using: &rng)
    }

    func answer(_ index: Int) {
        guard let question, feedback == nil else { return }
        let correct = index == question.correctIndex
        questionsAnswered += 1
        if correct { questionsCorrect += 1 }
        let earned = ledger.recordAnswer(correct: correct, tier: question.tier)
        feedback = AnswerFeedback(chosenIndex: index, isCorrect: correct, ammoEarned: earned)
    }

    func continueAfterAnswer() {
        guard let result = feedback else { return }
        question = nil
        feedback = nil
        if result.isCorrect {
            let shots = result.ammoEarned == 1 ? "1 shot" : "\(result.ammoEarned) shots"
            addLog("Loaded \(shots). Tap enemy waters to fire.")
        } else {
            addLog("Wrong answer, so no ammo this turn.")
            startEnemyTurn()
        }
    }

    // MARK: Firing

    func fire(at coordinate: Coordinate) {
        guard canFire, enemyBoard.shots[coordinate] == nil else { return }
        ledger.spend()
        let result = enemyBoard.fire(at: coordinate)
        addLog("You fired at \(coordinate.label): \(describe(result))")

        if enemyBoard.allSunk {
            phase = .won
            addLog("You sank the whole enemy fleet!")
        } else if ledger.ammo == 0 {
            startEnemyTurn()
        }
    }

    private func startEnemyTurn() {
        phase = .enemyTurn
        let scheduledFor = gameID
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            enemyTakesTurn(in: scheduledFor)
        }
    }

    private func enemyTakesTurn(in game: Int) {
        guard game == gameID, phase == .enemyTurn else { return }

        let answeredCorrectly = Double.random(in: 0..<1, using: &rng) < difficulty.accuracy
        if answeredCorrectly, let target = difficulty.strategy.nextShot(against: playerBoard, using: &rng) {
            let result = playerBoard.fire(at: target)
            addLog("Enemy fired at \(target.label): \(describe(result))")
            if playerBoard.allSunk {
                phase = .lost
                addLog("Your fleet has been sunk.")
                return
            }
        } else {
            addLog("Enemy got its question wrong and holds fire.")
        }
        phase = .playerTurn
    }

    // MARK: Helpers

    private func describe(_ result: ShotResult) -> String {
        switch result {
        case .miss: "miss."
        case .hit: "hit!"
        case .sunk(let type): "sunk the \(type.displayName)!"
        case .alreadyFired: "already fired there."
        }
    }

    private func addLog(_ entry: String) {
        log.insert(entry, at: 0)
        if log.count > 6 { log.removeLast(log.count - 6) }
    }
}
