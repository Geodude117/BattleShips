import SwiftUI

struct StatusBar: View {
    let model: GameViewModel

    var body: some View {
        HStack(spacing: 10) {
            stat("Ammo", value: "\(model.ammo)", icon: "flame.fill")
            stat("Streak", value: "\(model.ledger.streak)", icon: "bolt.fill")
            stat("Enemy ships", value: "\(model.enemyBoard.shipsRemaining)/5", icon: "scope")
            stat("Your ships", value: "\(model.playerBoard.shipsRemaining)/5", icon: "shield.fill")
        }
    }

    private func stat(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}
