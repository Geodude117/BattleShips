public enum Tier: String, CaseIterable, Sendable {
    case foundation
    case higher
}

public enum Topic: String, CaseIterable, Sendable {
    case fractions
    case percentages
    case ratio
    case linearEquations
    case area
    case probability
    case expandingBrackets
    case pythagoras

    public var displayName: String {
        switch self {
        case .fractions: "Fractions"
        case .percentages: "Percentages"
        case .ratio: "Ratio"
        case .linearEquations: "Linear equations"
        case .area: "Area"
        case .probability: "Probability"
        case .expandingBrackets: "Expanding brackets"
        case .pythagoras: "Pythagoras"
        }
    }

    public var tier: Tier {
        switch self {
        case .expandingBrackets, .pythagoras: .higher
        default: .foundation
        }
    }
}

/// A multiple-choice question with exactly four options.
public struct Question: Identifiable, Sendable {
    public let id: UInt64
    public let topic: Topic
    public let prompt: String
    public let options: [String]
    public let correctIndex: Int
    public let explanation: String

    public var tier: Tier { topic.tier }
    public var correctAnswer: String { options[correctIndex] }
}

extension Question {
    /// Builds a question from the correct answer and a list of likely wrong answers.
    /// Wrong answers that match the correct one or each other are skipped.
    static func build<G: RandomNumberGenerator>(
        topic: Topic,
        prompt: String,
        answer: String,
        candidates: [String],
        explanation: String,
        using rng: inout G
    ) -> Question {
        var distractors: [String] = []
        for candidate in candidates where candidate != answer && !distractors.contains(candidate) {
            distractors.append(candidate)
            if distractors.count == 3 { break }
        }
        for fallback in ["None of these", "Cannot be worked out", "0"] where distractors.count < 3 {
            if fallback != answer && !distractors.contains(fallback) { distractors.append(fallback) }
        }

        var options = distractors + [answer]
        options.shuffle(using: &rng)
        return Question(
            id: rng.next(),
            topic: topic,
            prompt: prompt,
            options: options,
            correctIndex: options.firstIndex(of: answer)!,
            explanation: explanation
        )
    }
}

public enum Maths {
    public static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? abs(a) : gcd(b, a % b)
    }

    /// A fraction in its simplest form, e.g. 6/8 → "3/4", 4/2 → "2".
    public static func fraction(_ numerator: Int, _ denominator: Int) -> String {
        let divisor = max(gcd(numerator, denominator), 1)
        var top = numerator / divisor
        var bottom = denominator / divisor
        if bottom < 0 {
            top = -top
            bottom = -bottom
        }
        return bottom == 1 ? "\(top)" : "\(top)/\(bottom)"
    }

    /// x² + bx + c with tidy signs, e.g. (1, -6) → "x² + x − 6".
    public static func quadratic(_ b: Int, _ c: Int) -> String {
        var text = "x²"
        if b != 0 {
            text += b > 0 ? " + " : " − "
            text += abs(b) == 1 ? "x" : "\(abs(b))x"
        }
        if c != 0 {
            text += c > 0 ? " + " : " − "
            text += "\(abs(c))"
        }
        return text
    }

    /// A signed x term: 1 → "x", -1 → "−x", 3 → "3x", -2 → "−2x".
    public static func xTerm(_ n: Int) -> String {
        let size = abs(n) == 1 ? "x" : "\(abs(n))x"
        return n < 0 ? "−" + size : size
    }

    /// A signed number using a proper minus sign: -6 → "−6".
    public static func signed(_ n: Int) -> String {
        n < 0 ? "−\(abs(n))" : "\(n)"
    }

    /// "(x + 3)" or "(x − 2)".
    public static func bracket(_ n: Int) -> String {
        n >= 0 ? "(x + \(n))" : "(x − \(abs(n)))"
    }
}
