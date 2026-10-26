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

    /// Column letter such as "A" or "J".
    public var columnLetter: String {
        String(Character(UnicodeScalar(UInt8(ascii: "A") + UInt8(column))))
    }

    /// Human-readable label such as "A1" or "J10".
    public var label: String {
        "\(columnLetter)\(row + 1)"
    }

    /// The up-to-four cells directly above, right, below and left, that are on the board.
    public var neighbours: [Coordinate] {
        [
            Coordinate(column: column, row: row - 1),
            Coordinate(column: column + 1, row: row),
            Coordinate(column: column, row: row + 1),
            Coordinate(column: column - 1, row: row)
        ].filter(\.isOnBoard)
    }

    /// This cell and the cells around it in a 3×3 square, clipped to the board.
    public var square: [Coordinate] {
        (-1...1).flatMap { dRow in
            (-1...1).map { dColumn in Coordinate(column: column + dColumn, row: row + dRow) }
        }
        .filter(\.isOnBoard)
    }

    /// This cell plus its four direct neighbours, clipped to the board.
    public var plus: [Coordinate] {
        [self] + neighbours
    }

    /// Every coordinate on the board, row by row.
    public static let all: [Coordinate] = (0..<boardSize).flatMap { row in
        (0..<boardSize).map { column in Coordinate(column: column, row: row) }
    }
}
