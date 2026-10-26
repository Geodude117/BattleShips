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
    case placing
    case playerTurn
    case enemyTurn
    case won
    case lost
}

struct AnswerFeedback: Equatable {
    let chosenIndex: Int
    let isCorrect: Bool
    let ammoEarned: Int
    let unlockedSpecial: Bool
    /// Extra shots from a run of correct answers, on top of the question's usual reward.
    let streakBonus: Int
}

/// The most recent shot, used to trigger haptics.
struct ShotEvent: Equatable {
    let id: Int
    let result: ShotResult
    let byPlayer: Bool
}

/// Runs one game: place your fleet, answer a question to load ammo, fire until it runs out,
/// then the enemy takes a turn.
@MainActor
@Observable
final class GameViewModel {
    private(set) var playerBoard = Board()
    private(set) var enemyBoard = Board()
    private(set) var ledger = AmmoLedger()
    private(set) var phase: Phase = .placing
    private(set) var feedback: AnswerFeedback?
    private(set) var log: [String] = []
    private(set) var questionsAnswered = 0
    private(set) var questionsCorrect = 0
    private(set) var lastShot: ShotEvent?
    var question: Question?
    var difficulty: Difficulty = .medium {
        didSet {
            if difficulty != oldValue { addLog("Difficulty set to \(difficulty.title).") }
        }
    }

    // Placement
    private(set) var selectedShip: ShipType? = .carrier
    private(set) var placementOrientation: Orientation = .horizontal

    // Special weapons
    private(set) var armedWeapon: SpecialWeapon?
    private(set) var sonarReadings: [Coordinate: Int] = [:]

    @ObservationIgnored private var rng = SeededGenerator(seed: 0)
    /// Bumped on every new game so an enemy turn scheduled in an old game never fires in a new one.
    @ObservationIgnored private var gameID = 0
    @ObservationIgnored private var shotCount = 0

    init() {
        newGame()
        #if DEBUG
        if let scene = ScreenshotScene.requested { loadScreenshotScene(scene) }
        #endif
    }

    var ammo: Int { ledger.ammo }
    var canFire: Bool { phase == .playerTurn && ledger.ammo > 0 && armedWeapon == nil }
    var canAsk: Bool { phase == .playerTurn && ledger.ammo == 0 && question == nil && armedWeapon == nil }
    var canUseSpecial: Bool { phase == .playerTurn && ledger.specialCharges > 0 && question == nil }
    var canStartBattle: Bool { phase == .placing && playerBoard.isFleetComplete }
    var isGameOver: Bool { phase == .won || phase == .lost }

    func newGame() {
        gameID += 1
        rng = SeededGenerator(seed: UInt64.random(in: 0...UInt64.max))
        playerBoard = Board()
        enemyBoard = Board.randomFleet(using: &rng)
        ledger = AmmoLedger()
        phase = .placing
        question = nil
        feedback = nil
        questionsAnswered = 0
        questionsCorrect = 0
        lastShot = nil
        selectedShip = .carrier
        placementOrientation = .horizontal
        armedWeapon = nil
        sonarReadings = [:]
        log = []
        addLog("New game on \(difficulty.title). Place your fleet.")
    }

    // MARK: Placement

    func selectShip(_ type: ShipType) {
        guard phase == .placing else { return }
        playerBoard.remove(type)
        selectedShip = type
    }

    func rotate() {
        placementOrientation = placementOrientation == .horizontal ? .vertical : .horizontal
    }

    /// Tap on an empty square places the selected ship there; tap on a placed ship picks it up to move it.
    func placementTapped(at coordinate: Coordinate) {
        guard phase == .placing else { return }
        if let existing = playerBoard.ship(at: coordinate) {
            playerBoard.remove(existing.type)
            selectedShip = existing.type
            return
        }
        guard let type = selectedShip else { return }
        if playerBoard.place(Ship(type: type, origin: coordinate, orientation: placementOrientation)) {
            selectedShip = playerBoard.unplacedTypes.first
        } else {
            addLog("The \(type.displayName) doesn't fit there. Try another square or rotate it.")
        }
    }

    func randomFleet() {
        guard phase == .placing else { return }
        playerBoard = Board.randomFleet(using: &rng)
        selectedShip = nil
    }

    func clearFleet() {
        guard phase == .placing else { return }
        playerBoard = Board()
        selectedShip = .carrier
    }

    func startBattle() {
        guard canStartBattle else { return }
        selectedShip = nil
        phase = .playerTurn
        addLog("Battle stations! Answer a question to load your guns.")
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
        let chargesBefore = ledger.specialCharges
        let earned = ledger.recordAnswer(correct: correct, tier: question.tier)
        let baseReward = question.tier == .higher ? 2 : 1
        feedback = AnswerFeedback(
            chosenIndex: index,
            isCorrect: correct,
            ammoEarned: earned,
            unlockedSpecial: ledger.specialCharges > chargesBefore,
            streakBonus: correct ? max(0, earned - baseReward) : 0
        )
    }

    func continueAfterAnswer() {
        guard let result = feedback else { return }
        question = nil
        feedback = nil
        if result.isCorrect {
            let shots = result.ammoEarned == 1 ? "1 shot" : "\(result.ammoEarned) shots"
            addLog("Loaded \(shots). Tap enemy waters to fire.")
            if result.unlockedSpecial {
                addLog("\(AmmoLedger.streakForSpecial) in a row! You unlocked a special weapon.")
            }
        } else {
            addLog("Wrong answer, so no ammo this turn.")
            startEnemyTurn()
        }
    }

    // MARK: Firing

    /// Routes a tap on the enemy board to the armed special weapon, or a normal shot.
    func enemyBoardTapped(at coordinate: Coordinate) {
        if let weapon = armedWeapon {
            useSpecial(weapon, at: coordinate)
        } else {
            fire(at: coordinate)
        }
    }

    func fire(at coordinate: Coordinate) {
        guard canFire, enemyBoard.shots[coordinate] == nil else { return }
        ledger.spend()
        let result = enemyBoard.fire(at: coordinate)
        recordShot(result, byPlayer: true)
        addLog("You fired at \(coordinate.label): \(describe(result))")
        finishPlayerAction()
    }

    // MARK: Special weapons

    func arm(_ weapon: SpecialWeapon?) {
        guard let weapon else {
            armedWeapon = nil
            return
        }
        guard canUseSpecial else { return }
        armedWeapon = weapon
        addLog("\(weapon.displayName) armed. \(weapon.instruction)")
    }

    private func useSpecial(_ weapon: SpecialWeapon, at coordinate: Coordinate) {
        guard canUseSpecial, ledger.useSpecial() else {
            armedWeapon = nil
            return
        }
        armedWeapon = nil

        switch weapon {
        case .sonar:
            let count = enemyBoard.sonarCount(around: coordinate)
            sonarReadings[coordinate] = count
            let sections = count == 1 ? "1 ship section" : "\(count) ship sections"
            addLog("Sonar around \(coordinate.label): \(sections) hidden nearby.")

        case .airstrike:
            var results: [ShotResult] = []
            for cell in coordinate.plus where enemyBoard.shots[cell] == nil {
                results.append(enemyBoard.fire(at: cell))
            }
            let hits = results.filter { $0 != .miss }.count
            addLog("Airstrike on \(coordinate.label): \(hits == 1 ? "1 hit" : "\(hits) hits").")
            for case .sunk(let type) in results {
                addLog("The airstrike sank the \(type.displayName)!")
            }
            let strongest = results.first { if case .sunk = $0 { true } else { false } }
                ?? results.first { $0 == .hit }
                ?? .miss
            recordShot(strongest, byPlayer: true)
            finishPlayerAction()
        }
    }

    // MARK: Turn flow

    /// After the player fires: check for a win, and hand over to the enemy once ammo runs out.
    private func finishPlayerAction() {
        if enemyBoard.allSunk {
            phase = .won
            addLog("You sank the whole enemy fleet!")
        } else if ledger.ammo == 0 {
            startEnemyTurn()
        }
    }

    private func startEnemyTurn() {
        phase = .enemyTurn
        armedWeapon = nil
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
            recordShot(result, byPlayer: false)
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

    // MARK: Screenshot scenes

    #if DEBUG
    /// Sets up a realistic mid-game position for App Store screenshots.
    /// Launch with `-screenshots battle` or `-screenshots question`. Debug builds only.
    func loadScreenshotScene(_ scene: ScreenshotScene) {
        gameID += 1
        rng = SeededGenerator(seed: 2026)
        playerBoard = Board.randomFleet(using: &rng)
        enemyBoard = Board.randomFleet(using: &rng)
        ledger = AmmoLedger()
        sonarReadings = [:]
        log = []
        selectedShip = nil
        phase = .playerTurn

        // Five correct answers in a row: 6 shots and a special weapon.
        for _ in 1...5 { ledger.recordAnswer(correct: true, tier: .foundation) }
        questionsAnswered = 6
        questionsCorrect = 5

        // Earlier turns: a few misses on both sides.
        let enemyWater = Coordinate.all.filter { enemyBoard.ship(at: $0) == nil }.shuffled(using: &rng)
        for cell in enemyWater.prefix(7) { _ = enemyBoard.fire(at: cell) }
        let playerWater = Coordinate.all.filter { playerBoard.ship(at: $0) == nil }.shuffled(using: &rng)
        for cell in playerWater.prefix(8) { _ = playerBoard.fire(at: cell) }
        if let cruiser = playerBoard.ships.first(where: { $0.type == .cruiser }) {
            for cell in cruiser.cells.prefix(2) { _ = playerBoard.fire(at: cell) }
        }

        // This turn: sink the Destroyer and hit the Carrier.
        if let destroyer = enemyBoard.ships.first(where: { $0.type == .destroyer }) {
            for cell in destroyer.cells {
                ledger.spend()
                _ = enemyBoard.fire(at: cell)
            }
        }
        var carrierHit = Coordinate(column: 0, row: 0)
        if let carrier = enemyBoard.ships.first(where: { $0.type == .carrier }) {
            carrierHit = carrier.cells[1]
            ledger.spend()
            _ = enemyBoard.fire(at: carrierHit)
        }

        // A sonar reading next to a hidden ship.
        if let probe = Coordinate.all.first(where: {
            enemyBoard.ship(at: $0) == nil && enemyBoard.shots[$0] == nil && enemyBoard.sonarCount(around: $0) >= 2
        }) {
            sonarReadings[probe] = enemyBoard.sonarCount(around: probe)
        }

        if let lastEnemyShot = playerWater.prefix(8).last {
            addLog("Enemy fired at \(lastEnemyShot.label): miss.")
        }
        addLog("You sank the Destroyer!")
        addLog("You fired at \(carrierHit.label): hit!")

        if scene == .question {
            while ledger.ammo > 0 { ledger.spend() }
            question = QuestionBank.make(.linearEquations, using: &rng)
        }
    }
    #endif

    // MARK: Helpers

    private func recordShot(_ result: ShotResult, byPlayer: Bool) {
        shotCount += 1
        lastShot = ShotEvent(id: shotCount, result: result, byPlayer: byPlayer)
    }

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
