public enum Orientation: String, CaseIterable, Sendable, Codable {
    case horizontal
    case vertical
}

/// A ship placed on a board, covering `type.length` consecutive cells.
public struct Ship: Hashable, Sendable, Codable, Identifiable {
    public let type: ShipType
    public let cells: [Coordinate]

    public var id: ShipType { type }

    public init(type: ShipType, origin: Coordinate, orientation: Orientation) {
        self.type = type
        self.cells = (0..<type.length).map { offset in
            switch orientation {
            case .horizontal: Coordinate(column: origin.column + offset, row: origin.row)
            case .vertical: Coordinate(column: origin.column, row: origin.row + offset)
            }
        }
    }
}
