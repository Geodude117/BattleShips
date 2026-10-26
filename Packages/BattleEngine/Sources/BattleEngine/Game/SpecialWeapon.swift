/// Bonus weapons unlocked by a streak of correct answers. Using one doesn't cost ammo.
public enum SpecialWeapon: String, CaseIterable, Identifiable, Sendable {
    /// Fires at a square and the four squares around it.
    case airstrike
    /// Reports how many ship sections are hidden in a 3×3 area, without firing.
    case sonar

    public var id: Self { self }

    public var displayName: String {
        switch self {
        case .airstrike: "Airstrike"
        case .sonar: "Sonar"
        }
    }

    public var systemImage: String {
        switch self {
        case .airstrike: "airplane"
        case .sonar: "dot.radiowaves.left.and.right"
        }
    }

    public var instruction: String {
        switch self {
        case .airstrike: "Tap enemy waters to hit a plus shape of five squares."
        case .sonar: "Tap enemy waters to scan a 3×3 area for ships."
        }
    }
}
