import SwiftUI
import BattleEngine

struct GameView: View {
    @State private var model = GameViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if model.phase == .placing {
                        PlacementPanel(model: model)
                    } else {
                        StatusBar(model: model)
                        actionArea
                        specialWeaponsBar
                        boards
                    }
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
            .sensoryFeedback(trigger: model.lastShot) { _, shot in
                haptic(for: shot)
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
                isActive: model.canFire || model.armedWeapon != nil,
                identifierPrefix: "enemy",
                badges: model.sonarReadings,
                onTap: { model.enemyBoardTapped(at: $0) }
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
        case .placing:
            EmptyView()
        case .playerTurn:
            if let weapon = model.armedWeapon {
                Label(weapon.instruction, systemImage: weapon.systemImage)
                    .font(.headline)
                    .foregroundStyle(.orange)
            } else if model.ammo > 0 {
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

    @ViewBuilder
    private var specialWeaponsBar: some View {
        if model.canUseSpecial || model.armedWeapon != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("Special weapons: \(model.ledger.specialCharges) ready")
                    .font(.subheadline.bold())
                HStack(spacing: 10) {
                    ForEach(SpecialWeapon.allCases) { weapon in
                        let isArmed = model.armedWeapon == weapon
                        Button {
                            model.arm(isArmed ? nil : weapon)
                        } label: {
                            Label(isArmed ? "Cancel" : weapon.displayName, systemImage: isArmed ? "xmark" : weapon.systemImage)
                        }
                        .buttonStyle(.bordered)
                        .tint(isArmed ? Color.orange : Color.purple)
                        .accessibilityIdentifier("special-\(weapon.rawValue)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
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

    private func haptic(for shot: ShotEvent?) -> SensoryFeedback? {
        guard let shot else { return nil }
        switch shot.result {
        case .sunk: return .impact(weight: .heavy, intensity: 1)
        case .hit: return .impact(weight: .medium)
        case .miss: return .impact(weight: .light, intensity: 0.5)
        case .alreadyFired: return nil
        }
    }
}

#Preview {
    GameView()
}
