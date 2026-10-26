import SwiftUI
import BattleEngine

struct BoardView: View {
    let title: String
    let board: Board
    let revealShips: Bool
    var isActive = false
    /// Prefix for UI-test identifiers, e.g. "enemy" gives "enemy-A1".
    var identifierPrefix = "board"
    /// Numbers to show on cells, e.g. sonar readings.
    var badges: [Coordinate: Int] = [:]
    var onTap: (Coordinate) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                GridRow {
                    Text("")
                    ForEach(0..<Coordinate.boardSize, id: \.self) { column in
                        Text(Coordinate(column: column, row: 0).columnLetter)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(0..<Coordinate.boardSize, id: \.self) { row in
                    GridRow {
                        Text("\(row + 1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(0..<Coordinate.boardSize, id: \.self) { column in
                            let coordinate = Coordinate(column: column, row: row)
                            CellView(
                                state: board.state(at: coordinate),
                                hasShip: revealShips && board.ship(at: coordinate) != nil,
                                badge: badges[coordinate]
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { onTap(coordinate) }
                            .accessibilityLabel(coordinate.label)
                            .accessibilityValue(spokenState(at: coordinate))
                            .accessibilityIdentifier("\(identifierPrefix)-\(coordinate.label)")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .frame(maxWidth: 520)
    }

    private func spokenState(at coordinate: Coordinate) -> String {
        switch board.state(at: coordinate) {
        case .miss: return "Miss"
        case .hit: return "Hit"
        case .sunk: return "Sunk"
        case .unknown:
            if let reading = badges[coordinate] { return "Sonar reading \(reading)" }
            return revealShips && board.ship(at: coordinate) != nil ? "Ship" : "Water"
        }
    }
}

struct CellView: View {
    let state: CellState
    let hasShip: Bool
    var badge: Int? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(fill)
            .aspectRatio(1, contentMode: .fit)
            .overlay { marker }
            .overlay {
                if let badge, state == .unknown {
                    Text("\(badge)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.purple.opacity(0.85), in: RoundedRectangle(cornerRadius: 3))
                }
            }
            .animation(.easeOut(duration: 0.2), value: state)
    }

    private var fill: Color {
        switch state {
        case .unknown: hasShip ? Color.gray.opacity(0.6) : Color.blue.opacity(0.3)
        case .miss: Color.blue.opacity(0.12)
        case .hit: Color.orange
        case .sunk: Color.red.opacity(0.8)
        }
    }

    @ViewBuilder
    private var marker: some View {
        switch state {
        case .miss:
            Circle()
                .fill(Color.white.opacity(0.8))
                .scaleEffect(0.3)
        case .hit, .sunk:
            Image(systemName: "xmark")
                .font(.caption.bold())
                .foregroundStyle(.white)
        case .unknown:
            EmptyView()
        }
    }
}
