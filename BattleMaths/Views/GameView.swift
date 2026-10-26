import SwiftUI
import BattleEngine

struct GameView: View {
    @State private var model = GameViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatusBar(model: model)
                    actionArea
                    boards
                    logView
                }
                .padding()
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("BattleMaths")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Difficulty", selection: $model.difficulty) {
                            ForEach(Difficulty.allCases) { level in
                                Text(level.title).tag(level)
                            }
                        }
                        Button("New game", systemImage: "arrow.clockwise") {
                            model.newGame()
                        }
                    } label: {
                        Label("Game options", systemImage: "gearshape")
                    }
                }
            }
            .sheet(item: $model.question) { question in
                QuestionSheet(question: question, model: model)
                    .interactiveDismissDisabled()
            }
        }
    }

    private var boards: some View {
        let layout = sizeClass == .regular
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 24))
            : AnyLayout(VStackLayout(spacing: 24))

        return layout {
            BoardView(
                title: "Enemy waters",
                board: model.enemyBoard,
                revealShips: model.isGameOver,
                isActive: model.canFire,
                identifierPrefix: "enemy",
                onTap: { model.fire(at: $0) }
            )
            BoardView(
                title: "Your fleet",
                board: model.playerBoard,
                revealShips: true,
                identifierPrefix: "player"
            )
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        switch model.phase {
        case .playerTurn:
            if model.ammo > 0 {
                Label("Tap enemy waters to fire (\(model.ammo) left)", systemImage: "scope")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            } else {
                Button {
                    model.askQuestion()
                } label: {
                    Label("Answer a question to load ammo", systemImage: "questionmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        case .enemyTurn:
            HStack(spacing: 8) {
                ProgressView()
                Text("Enemy is taking its turn…")
            }
            .font(.headline)
        case .won, .lost:
            VStack(spacing: 12) {
                Text(model.phase == .won ? "You win!" : "You lost this one.")
                    .font(.title2.bold())
                Text("You answered \(model.questionsCorrect) of \(model.questionsAnswered) questions correctly.")
                    .foregroundStyle(.secondary)
                Button("Play again") {
                    model.newGame()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var logView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(model.log.enumerated()), id: \.offset) { index, entry in
                Text(entry)
                    .font(index == 0 ? .body : .footnote)
                    .foregroundStyle(index == 0 ? .primary : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    GameView()
}
