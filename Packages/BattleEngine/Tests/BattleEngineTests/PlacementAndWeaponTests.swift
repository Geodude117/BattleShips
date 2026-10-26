import Testing
import BattleEngine

struct PlacementTests {
    @Test func fleetTracksWhatIsLeftToPlace() {
        var board = Board()
        #expect(board.unplacedTypes == ShipType.allCases)
        board.place(Ship(type: .carrier, origin: Coordinate(column: 0, row: 0), orientation: .horizontal))
        #expect(board.unplacedTypes.first == .battleship)
        #expect(!board.isFleetComplete)
    }

    @Test func cannotPlaceTheSameShipTwice() {
        var board = Board()
        let first = board.place(Ship(type: .destroyer, origin: Coordinate(column: 0, row: 0), orientation: .horizontal))
        let second = board.place(Ship(type: .destroyer, origin: Coordinate(column: 0, row: 5), orientation: .horizontal))
        #expect(first)
        #expect(!second)
    }

    @Test func shipsCanBeMovedBeforeTheBattle() {
        var board = Board()
        board.place(Ship(type: .cruiser, origin: Coordinate(column: 0, row: 0), orientation: .vertical))
        let removed = board.remove(.cruiser)
        #expect(removed?.type == .cruiser)
        #expect(board.ships.isEmpty)
        let movedAgain = board.place(Ship(type: .cruiser, origin: Coordinate(column: 5, row: 5), orientation: .horizontal))
        #expect(movedAgain)
    }

    @Test func shipsCannotBeMovedOnceFiredAt() {
        var board = Board()
        board.place(Ship(type: .cruiser, origin: Coordinate(column: 0, row: 0), orientation: .vertical))
        _ = board.fire(at: Coordinate(column: 9, row: 9))
        let removed = board.remove(.cruiser)
        #expect(removed == nil)
        #expect(board.ships.count == 1)
    }
}

struct ShapeTests {
    @Test func squareAndPlusAreClippedToTheBoard() {
        #expect(Coordinate(column: 5, row: 5).square.count == 9)
        #expect(Coordinate(column: 0, row: 0).square.count == 4)
        #expect(Coordinate(column: 5, row: 5).plus.count == 5)
        #expect(Coordinate(column: 0, row: 0).plus.count == 3)
    }
}

struct SpecialWeaponTests {
    @Test func fiveInARowUnlocksASpecialCharge() {
        var ledger = AmmoLedger()
        for _ in 1...4 { ledger.recordAnswer(correct: true, tier: .foundation) }
        let chargesAfterFour = ledger.specialCharges
        ledger.recordAnswer(correct: true, tier: .foundation)
        let chargesAfterFive = ledger.specialCharges
        let used = ledger.useSpecial()
        let usedAgain = ledger.useSpecial()
        #expect(chargesAfterFour == 0)
        #expect(chargesAfterFive == 1)
        #expect(used)
        #expect(!usedAgain)
    }

    @Test func wrongAnswerResetsProgressTowardsASpecial() {
        var ledger = AmmoLedger()
        for _ in 1...4 { ledger.recordAnswer(correct: true, tier: .foundation) }
        ledger.recordAnswer(correct: false, tier: .foundation)
        ledger.recordAnswer(correct: true, tier: .foundation)
        #expect(ledger.specialCharges == 0)
    }

    @Test func sonarCountsOnlyUnhitShipSections() {
        var board = Board()
        board.place(Ship(type: .destroyer, origin: Coordinate(column: 4, row: 4), orientation: .horizontal)) // E5, F5
        let centre = Coordinate(column: 5, row: 5) // F6
        let before = board.sonarCount(around: centre)
        _ = board.fire(at: Coordinate(column: 4, row: 4))
        let after = board.sonarCount(around: centre)
        let farAway = board.sonarCount(around: Coordinate(column: 0, row: 9))
        #expect(before == 2)
        #expect(after == 1)
        #expect(farAway == 0)
    }
}
