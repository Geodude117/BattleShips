/// How the computer chooses where to fire. It only uses what a player could see:
/// which cells have been fired at, which were hits, and which ships are sunk.
public enum AIStrategy: Sendable {
    /// Fires at any cell it hasn't tried yet.
    case random
    /// Hunts on a checkerboard until it gets a hit, then finishes off the wounded ship.
    case huntTarget

    public func nextShot<G: RandomNumberGenerator>(against board: Board, using rng: inout G) -> Coordinate? {
        let open = Coordinate.all.filter { board.shots[$0] == nil }
        guard !open.isEmpty else { return nil }

        if self == .huntTarget {
            let wounded = Set(Coordinate.all.filter { board.state(at: $0) == .hit })
            let targets = open.filter { cell in cell.neighbours.contains { wounded.contains($0) } }

            if !targets.isEmpty {
                // Prefer cells that extend a line of two or more hits.
                let inLine = targets.filter { cell in
                    cell.neighbours.contains { hit in
                        wounded.contains(hit)
                            && wounded.contains(Coordinate(column: 2 * hit.column - cell.column, row: 2 * hit.row - cell.row))
                    }
                }
                return (inLine.isEmpty ? targets : inLine).randomElement(using: &rng)
            }

            // Every ship is at least 2 long, so a checkerboard pattern is enough to find them all.
            let parity = open.filter { ($0.column + $0.row).isMultiple(of: 2) }
            if !parity.isEmpty { return parity.randomElement(using: &rng) }
        }

        return open.randomElement(using: &rng)
    }
}
