import SwiftUI
import BattleEngine

/// Before the battle: pick a ship, choose its direction, and tap the grid to place it.
struct PlacementPanel: View {
    let model: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Place your fleet")
                .font(.title2.bold())

            Text(instruction)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShipType.allCases, id: \.self) { type in
                        shipChip(type)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    model.rotate()
                } label: {
                    Label(
                        model.placementOrientation == .horizontal ? "Horizontal" : "Vertical",
                        systemImage: model.placementOrientation == .horizontal ? "arrow.left.and.right" : "arrow.up.and.down"
                    )
                }
                .accessibilityIdentifier("rotate")

                Button("Random fleet", systemImage: "shuffle") {
                    model.randomFleet()
                }

                Button("Clear", systemImage: "trash") {
                    model.clearFleet()
                }
                .disabled(model.playerBoard.ships.isEmpty)
            }
            .buttonStyle(.bordered)

            BoardView(
                title: "Your fleet",
                board: model.playerBoard,
                revealShips: true,
                isActive: model.selectedShip != nil,
                identifierPrefix: "player",
                onTap: { model.placementTapped(at: $0) }
            )

            Button {
                model.startBattle()
            } label: {
                Label("Start battle", systemImage: "flag.checkered")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.canStartBattle)
        }
        .frame(maxWidth: 520)
    }

    private var instruction: String {
        if let ship = model.selectedShip {
            return "Tap a square to place your \(ship.displayName) (\(ship.length) squares), starting from its \(model.placementOrientation == .horizontal ? "left" : "top") end. Tap a placed ship to move it."
        }
        return "Fleet ready! Tap a ship to move it, or start the battle."
    }

    private func shipChip(_ type: ShipType) -> some View {
        let placed = model.playerBoard.ships.contains { $0.type == type }
        let selected = model.selectedShip == type

        return Button {
            model.selectShip(type)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .fixedSize()
                    if placed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                HStack(spacing: 2) {
                    ForEach(0..<type.length, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(placed ? Color.gray : Color.accentColor)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(10)
            .background(
                selected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ship-\(type.rawValue)")
    }
}
