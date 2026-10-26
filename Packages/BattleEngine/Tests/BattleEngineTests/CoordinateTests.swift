import Testing
import BattleEngine

struct CoordinateTests {
    @Test func boardHasOneHundredCells() {
        #expect(Coordinate.all.count == 100)
        #expect(Set(Coordinate.all).count == 100)
    }

    @Test(arguments: [
        (0, 0, "A1"),
        (2, 4, "C5"),
        (9, 9, "J10")
    ])
    func labels(column: Int, row: Int, expected: String) {
        #expect(Coordinate(column: column, row: row).label == expected)
    }

    @Test func onBoardChecks() {
        #expect(Coordinate(column: 0, row: 0).isOnBoard)
        #expect(Coordinate(column: 9, row: 9).isOnBoard)
        #expect(!Coordinate(column: 10, row: 0).isOnBoard)
        #expect(!Coordinate(column: 0, row: -1).isOnBoard)
    }
}

struct ShipTypeTests {
    @Test func fleetCoversSeventeenCells() {
        let totalCells = ShipType.allCases.map { $0.length }.reduce(0, +)
        #expect(totalCells == 17)
    }
}
