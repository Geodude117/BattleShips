/// One player's fleet plus every shot fired at it.
public struct Board: Sendable {
    public private(set) var ships: [Ship] = []
    public private(set) var shots: [Coordinate: ShotResult] = [:]

    public init() {}

    // MARK: Placement

    public func canPlace(_ ship: Ship) -> Bool {
        let occupied = Set(ships.flatMap(\.cells))
        return ship.cells.allSatisfy { $0.isOnBoard && !occupied.contains($0) }
    }

    @discardableResult
    public mutating func place(_ ship: Ship) -> Bool {
        guard canPlace(ship) else { return false }
        ships.append(ship)
        return true
    }

    /// A board with the full fleet placed at random, never overlapping or off the edge.
    public static func randomFleet<G: RandomNumberGenerator>(using rng: inout G) -> Board {
        var board = Board()
        for type in ShipType.allCases {
            var placed = false
            while !placed {
                let orientation = Orientation.allCases.randomElement(using: &rng)!
                let origin = Coordinate.all.randomElement(using: &rng)!
                placed = board.place(Ship(type: type, origin: origin, orientation: orientation))
            }
        }
        return board
    }

    // MARK: Firing

    public func ship(at coordinate: Coordinate) -> Ship? {
        ships.first { $0.cells.contains(coordinate) }
    }

    public func isSunk(_ ship: Ship) -> Bool {
        ship.cells.allSatisfy { shots[$0] != nil }
    }

    public mutating func fire(at coordinate: Coordinate) -> ShotResult {
        guard coordinate.isOnBoard, shots[coordinate] == nil else { return .alreadyFired }
        guard let target = ship(at: coordinate) else {
            shots[coordinate] = .miss
            return .miss
        }
        shots[coordinate] = .hit
        return isSunk(target) ? .sunk(target.type) : .hit
    }

    // MARK: State

    public var sunkShips: [ShipType] {
        ships.filter { isSunk($0) }.map(\.type)
    }

    public var shipsRemaining: Int {
        ships.count - sunkShips.count
    }

    public var allSunk: Bool {
        !ships.isEmpty && ships.allSatisfy { isSunk($0) }
    }

    public func state(at coordinate: Coordinate) -> CellState {
        guard let result = shots[coordinate] else { return .unknown }
        if result == .miss { return .miss }
        if let found = ship(at: coordinate), isSunk(found) { return .sunk }
        return .hit
    }
}
