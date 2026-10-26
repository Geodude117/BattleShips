import Testing
import BattleEngine

struct QuestionTests {
    @Test(arguments: Topic.allCases)
    func everyQuestionHasFourDistinctOptionsAndOneCorrectAnswer(topic: Topic) {
        var rng = SeededGenerator(seed: 2026)
        for _ in 0..<1_000 {
            let question = QuestionBank.make(topic, using: &rng)
            #expect(question.options.count == 4)
            #expect(Set(question.options).count == 4)
            #expect(question.options.indices.contains(question.correctIndex))
            #expect(!question.options.contains("None of these"), "Ran out of distractors: \(question.prompt)")
        }
    }

    @Test func sameSeedGivesSameQuestions() {
        var first = SeededGenerator(seed: 99)
        var second = SeededGenerator(seed: 99)
        for _ in 0..<20 {
            let a = QuestionBank.random(using: &first)
            let b = QuestionBank.random(using: &second)
            #expect(a.prompt == b.prompt)
            #expect(a.options == b.options)
        }
    }

    @Test func fractionsSimplify() {
        #expect(Maths.fraction(6, 8) == "3/4")
        #expect(Maths.fraction(4, 2) == "2")
        #expect(Maths.quadratic(1, -6) == "x² + x − 6")
        #expect(Maths.quadratic(-5, 6) == "x² − 5x + 6")
    }

    @Test func percentageAnswerIsCorrect() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<200 {
            let question = QuestionBank.make(.percentages, using: &rng)
            // Prompt: "Increase £A by P%"
            let words = question.prompt.split(separator: " ")
            let amount = Int(words[1].dropFirst())!
            let percent = Int(words[3].dropLast())!
            #expect(question.correctAnswer == "£\(amount + amount * percent / 100)")
        }
    }
}

struct MathsFormattingTests {
    @Test func xTermsAndSignsReadNaturally() {
        #expect(Maths.xTerm(1) == "x")
        #expect(Maths.xTerm(-1) == "−x")
        #expect(Maths.xTerm(3) == "3x")
        #expect(Maths.xTerm(-2) == "−2x")
        #expect(Maths.signed(-6) == "−6")
        #expect(Maths.signed(4) == "4")
    }
}
