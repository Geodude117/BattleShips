/// A cell on the board. `column` and `row` are zero-based.
/// Column 0 is "A" and row 0 is "1", so `Coordinate(column: 2, row: 4)` is "C5".
public struct Coordinate: Hashable, Sendable, Codable {
    public static let boardSize = 10

    public let column: Int
    public let row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }

    /// Whether this coordinate sits inside a standard 10×10 board.
    public var isOnBoard: Bool {
        (0..<Self.boardSize).contains(column) && (0..<Self.boardSize).contains(row)
    }

    /// Human-readable label such as "A1" or "J10".
    public var label: String {
        let letter = Character(UnicodeScalar(UInt8(ascii: "A") + UInt8(column)))
        return "\(letter)\(row + 1)"
    }

    /// Every coordinate on the board, row by row.
    public static let all: [Coordinate] = (0..<boardSize).flatMap { row in
        (0..<boardSize).map { column in Coordinate(column: column, row: row) }
    }
}
