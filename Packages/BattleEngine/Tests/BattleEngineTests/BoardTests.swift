import Testing
import BattleEngine

struct BoardTests {
    @Test func randomFleetPlacesEveryShipWithoutOverlap() {
        for seed in 0..<200 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let board = Board.randomFleet(using: &rng)
            let cells = board.ships.flatMap(\.cells)
            #expect(board.ships.count == 5)
            #expect(cells.count == 17)
            #expect(Set(cells).count == 17)
            let allOnBoard = cells.allSatisfy { $0.isOnBoard }
            #expect(allOnBoard)
        }
    }

    @Test func cannotPlaceOffTheBoardOrOverlapping() {
        var board = Board()
        let offEdge = board.place(Ship(type: .carrier, origin: Coordinate(column: 7, row: 0), orientation: .horizontal))
        let valid = board.place(Ship(type: .carrier, origin: Coordinate(column: 0, row: 0), orientation: .horizontal))
        let overlapping = board.place(Ship(type: .destroyer, origin: Coordinate(column: 2, row: 0), orientation: .vertical))
        #expect(!offEdge)
        #expect(valid)
        #expect(!overlapping)
        #expect(board.ships.count == 1)
    }

    @Test func firingReportsMissHitAndSunk() {
        var board = Board()
        board.place(Ship(type: .destroyer, origin: Coordinate(column: 0, row: 0), orientation: .horizontal))

        let miss = board.fire(at: Coordinate(column: 5, row: 5))
        let hit = board.fire(at: Coordinate(column: 0, row: 0))
        let repeated = board.fire(at: Coordinate(column: 0, row: 0))
        let stateAfterHit = board.state(at: Coordinate(column: 0, row: 0))
        let sunk = board.fire(at: Coordinate(column: 1, row: 0))
        let stateAfterSink = board.state(at: Coordinate(column: 0, row: 0))

        #expect(miss == .miss)
        #expect(hit == .hit)
        #expect(repeated == .alreadyFired)
        #expect(stateAfterHit == .hit)
        #expect(sunk == .sunk(.destroyer))
        #expect(stateAfterSink == .sunk)
        #expect(board.allSunk)
        #expect(board.shipsRemaining == 0)
    }

    @Test func firingOffTheBoardIsRejected() {
        var board = Board()
        let result = board.fire(at: Coordinate(column: 10, row: 0))
        #expect(result == .alreadyFired)
        #expect(board.shots.isEmpty)
    }
}

struct AmmoLedgerTests {
    @Test func correctAnswersEarnAmmoAndStreakBonus() {
        var ledger = AmmoLedger()
        let first = ledger.recordAnswer(correct: true, tier: .foundation)
        let second = ledger.recordAnswer(correct: true, tier: .higher)
        let third = ledger.recordAnswer(correct: true, tier: .foundation) // third in a row: +1 bonus
        #expect(first == 1)
        #expect(second == 2)
        #expect(third == 2)
        #expect(ledger.ammo == 5)

        let wrong = ledger.recordAnswer(correct: false, tier: .foundation)
        #expect(wrong == 0)
        #expect(ledger.streak == 0)
        #expect(ledger.ammo == 5)
    }

    @Test func cannotSpendWithoutAmmo() {
        var ledger = AmmoLedger()
        let spentWhenEmpty = ledger.spend()
        ledger.recordAnswer(correct: true, tier: .foundation)
        let spentWithAmmo = ledger.spend()
        #expect(!spentWhenEmpty)
        #expect(spentWithAmmo)
        #expect(ledger.ammo == 0)
    }
}

struct AIStrategyTests {
    @Test(arguments: [AIStrategy.random, AIStrategy.huntTarget])
    func sinksTheWholeFleetWithoutRepeatingAShot(strategy: AIStrategy) {
        for seed in 0..<50 {
            var rng = SeededGenerator(seed: UInt64(seed))
            var board = Board.randomFleet(using: &rng)
            var shots = 0
            var repeats = 0
            while !board.allSunk, let target = strategy.nextShot(against: board, using: &rng) {
                let result = board.fire(at: target)
                if result == .alreadyFired { repeats += 1 }
                shots += 1
            }
            #expect(repeats == 0)
            #expect(board.allSunk)
            #expect(shots <= 100)
        }
    }

    @Test func huntTargetBeatsRandomOnAverage() {
        func averageShots(_ strategy: AIStrategy) -> Double {
            var total = 0
            for seed in 0..<200 {
                var rng = SeededGenerator(seed: UInt64(seed))
                var board = Board.randomFleet(using: &rng)
                while !board.allSunk, let target = strategy.nextShot(against: board, using: &rng) {
                    _ = board.fire(at: target)
                    total += 1
                }
            }
            return Double(total) / 200
        }
        let hunt = averageShots(.huntTarget)
        let random = averageShots(.random)
        #expect(hunt < random)
    }
}
