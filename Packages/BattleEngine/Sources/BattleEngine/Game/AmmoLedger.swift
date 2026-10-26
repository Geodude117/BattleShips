/// Tracks the player's ammo and answer streak.
/// Foundation questions earn 1 shot, Higher earn 2, and every third correct answer in a row earns a bonus shot.
/// Every fifth correct answer in a row also unlocks a special weapon charge.
public struct AmmoLedger: Sendable {
    public static let streakForSpecial = 5

    public private(set) var ammo = 0
    public private(set) var streak = 0
    public private(set) var specialCharges = 0

    public init() {}

    @discardableResult
    public mutating func recordAnswer(correct: Bool, tier: Tier) -> Int {
        guard correct else {
            streak = 0
            return 0
        }
        streak += 1
        var earned = tier == .higher ? 2 : 1
        if streak.isMultiple(of: 3) { earned += 1 }
        if streak.isMultiple(of: Self.streakForSpecial) { specialCharges += 1 }
        ammo += earned
        return earned
    }

    @discardableResult
    public mutating func useSpecial() -> Bool {
        guard specialCharges > 0 else { return false }
        specialCharges -= 1
        return true
    }

    @discardableResult
    public mutating func spend() -> Bool {
        guard ammo > 0 else { return false }
        ammo -= 1
        return true
    }
}
