import SwiftUI
import BattleEngine

/// Placeholder home screen: draws an empty 10×10 board from the engine
/// to prove the app target is linked to the BattleEngine package.
struct ContentView: View {
    private let size = Coordinate.boardSize

    var body: some View {
        VStack(spacing: 24) {
            Text("BattleMaths")
                .font(.largeTitle.bold())

            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                ForEach(0..<size, id: \.self) { row in
                    GridRow {
                        ForEach(0..<size, id: \.self) { column in
                            let coordinate = Coordinate(column: column, row: row)
                            Rectangle()
                                .fill(.blue.opacity(0.2))
                                .aspectRatio(1, contentMode: .fit)
                                .accessibilityLabel(coordinate.label)
                        }
                    }
                }
            }
            .frame(maxWidth: 500)

            Text("Answer maths questions to earn ammo.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
