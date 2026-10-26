import SwiftUI
import BattleEngine

struct QuestionSheet: View {
    let question: Question
    let model: GameViewModel

    private var feedback: AnswerFeedback? { model.feedback }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(question.topic.displayName.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(question.tier == .higher ? "Higher · 2 shots" : "Foundation · 1 shot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(question.prompt)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        Button {
                            model.answer(index)
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.title3)
                                Spacer()
                                if let icon = icon(for: index) {
                                    Image(systemName: icon)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(background(for: index), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(feedback != nil)
                        .accessibilityIdentifier("answer-\(index)")
                    }
                }

                if let feedback {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(feedback.isCorrect ? "Correct! +\(feedback.ammoEarned) ammo" : "Not quite.")
                            .font(.headline)
                            .foregroundStyle(feedback.isCorrect ? Color.green : Color.red)
                        if feedback.unlockedSpecial {
                            Label("Special weapon unlocked!", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(.purple)
                        }
                        Text(question.explanation)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        model.continueAfterAnswer()
                    } label: {
                        Text(feedback.isCorrect ? "Fire away" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
        }
        .sensoryFeedback(trigger: model.feedback) { _, newFeedback in
            newFeedback.map { $0.isCorrect ? SensoryFeedback.success : SensoryFeedback.error }
        }
    }

    private func background(for index: Int) -> Color {
        guard let feedback else { return Color.secondary.opacity(0.12) }
        if index == question.correctIndex { return Color.green.opacity(0.3) }
        if index == feedback.chosenIndex { return Color.red.opacity(0.3) }
        return Color.secondary.opacity(0.06)
    }

    private func icon(for index: Int) -> String? {
        guard let feedback else { return nil }
        if index == question.correctIndex { return "checkmark.circle.fill" }
        if index == feedback.chosenIndex { return "xmark.circle.fill" }
        return nil
    }
}
