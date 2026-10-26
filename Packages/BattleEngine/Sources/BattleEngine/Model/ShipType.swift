/// The classic five-ship fleet.
public enum ShipType: String, CaseIterable, Sendable, Codable {
    case carrier
    case battleship
    case cruiser
    case submarine
    case destroyer

    /// Number of cells the ship covers.
    public var length: Int {
        switch self {
        case .carrier: 5
        case .battleship: 4
        case .cruiser: 3
        case .submarine: 3
        case .destroyer: 2
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}
