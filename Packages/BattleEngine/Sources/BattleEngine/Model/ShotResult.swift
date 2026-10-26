/// What happened when a shot landed.
public enum ShotResult: Equatable, Sendable {
    case miss
    case hit
    case sunk(ShipType)
    case alreadyFired
}

/// What a cell looks like to the player who is firing at it.
public enum CellState: Equatable, Sendable {
    case unknown
    case miss
    case hit
    case sunk
}
