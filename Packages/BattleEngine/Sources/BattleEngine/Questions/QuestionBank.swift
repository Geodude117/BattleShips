/// Generates GCSE-style questions. Numbers are random each time, the correct answer is always
/// computed, and the wrong options come from common mistakes for that topic.
public enum QuestionBank {
    public static func random<G: RandomNumberGenerator>(using rng: inout G) -> Question {
        let topic = Topic.allCases.randomElement(using: &rng)!
        return make(topic, using: &rng)
    }

    public static func make<G: RandomNumberGenerator>(_ topic: Topic, using rng: inout G) -> Question {
        switch topic {
        case .fractions: fractions(&rng)
        case .percentages: percentages(&rng)
        case .ratio: ratio(&rng)
        case .linearEquations: linearEquation(&rng)
        case .area: triangleArea(&rng)
        case .probability: probability(&rng)
        case .expandingBrackets: expandingBrackets(&rng)
        case .pythagoras: pythagoras(&rng)
        }
    }

    // MARK: Foundation

    static func fractions<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let b = Int.random(in: 2...9, using: &rng)
        var d = Int.random(in: 2...9, using: &rng)
        while d == b { d = Int.random(in: 2...9, using: &rng) }
        let a = Int.random(in: 1..<b, using: &rng)
        let c = Int.random(in: 1..<d, using: &rng)
        let top = a * d + c * b
        let bottom = b * d
        let answer = Maths.fraction(top, bottom)

        return .build(
            topic: .fractions,
            prompt: "Work out \(a)/\(b) + \(c)/\(d)",
            answer: answer,
            candidates: [
                Maths.fraction(a + c, b + d),
                Maths.fraction(a + c, bottom),
                Maths.fraction(a * c, bottom),
                Maths.fraction(top + 1, bottom),
                Maths.fraction(top, b + d),
                Maths.fraction(top - 1, bottom)
            ],
            explanation: "Use a common denominator of \(bottom): \(a)/\(b) = \(a * d)/\(bottom) and \(c)/\(d) = \(c * b)/\(bottom). Add the numerators to get \(top)/\(bottom), which is \(answer) in its simplest form. Never add the bottoms together.",
            using: &rng
        )
    }

    static func percentages<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let amount = 20 * Int.random(in: 1...10, using: &rng)
        let percent = [5, 10, 15, 20, 25, 30, 40].randomElement(using: &rng)!
        let increase = amount * percent / 100
        let total = amount + increase

        return .build(
            topic: .percentages,
            prompt: "Increase £\(amount) by \(percent)%",
            answer: "£\(total)",
            candidates: [
                "£\(amount + percent)",
                "£\(increase)",
                "£\(amount - increase)",
                "£\(amount + 2 * increase)",
                "£\(total + 10)"
            ],
            explanation: "\(percent)% of £\(amount) is £\(amount) × \(percent) ÷ 100 = £\(increase). Add it on: £\(amount) + £\(increase) = £\(total).",
            using: &rng
        )
    }

    static func ratio<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let p = Int.random(in: 1...5, using: &rng)
        var q = Int.random(in: 1...5, using: &rng)
        while q == p { q = Int.random(in: 1...5, using: &rng) }
        let part = Int.random(in: 2...12, using: &rng)
        let parts = p + q
        let total = parts * part
        let larger = max(p, q) * part
        let smaller = min(p, q) * part

        return .build(
            topic: .ratio,
            prompt: "Share £\(total) in the ratio \(p):\(q). How much is the larger share?",
            answer: "£\(larger)",
            candidates: [
                "£\(smaller)",
                "£\(larger + part)",
                "£\(total - part)",
                "£\(total / 2)",
                "£\(max(p, q) * 10)",
                "£\(larger - part)"
            ],
            explanation: "There are \(p) + \(q) = \(parts) parts, so one part is £\(total) ÷ \(parts) = £\(part). The larger share is \(max(p, q)) × £\(part) = £\(larger).",
            using: &rng
        )
    }

    static func linearEquation<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let a = Int.random(in: 2...9, using: &rng)
        let x = Int.random(in: 1...12, using: &rng)
        let b = Int.random(in: 1...20, using: &rng)
        let c = a * x + b

        return .build(
            topic: .linearEquations,
            prompt: "Solve \(a)x + \(b) = \(c)",
            answer: "x = \(x)",
            candidates: [
                "x = \(Maths.fraction(c + b, a))",
                "x = \(c - b)",
                "x = \(Maths.fraction(c, a))",
                "x = \(x + 1)",
                "x = \(x - 1)"
            ],
            explanation: "Subtract \(b) from both sides: \(a)x = \(c - b). Then divide both sides by \(a): x = \(x).",
            using: &rng
        )
    }

    static func triangleArea<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        var base = Int.random(in: 2...20, using: &rng)
        let height = Int.random(in: 2...20, using: &rng)
        if !(base * height).isMultiple(of: 2) { base += 1 }
        let area = base * height / 2

        return .build(
            topic: .area,
            prompt: "A triangle has a base of \(base) cm and a height of \(height) cm. What is its area?",
            answer: "\(area) cm²",
            candidates: [
                "\(base * height) cm²",
                "\(base + height) cm²",
                "\(2 * (base + height)) cm²",
                "\(area + base) cm²",
                "\(area + height) cm²",
                "\(area + 1) cm²",
                "\(area - 1) cm²"
            ],
            explanation: "Area of a triangle = ½ × base × height = ½ × \(base) × \(height) = \(area) cm².",
            using: &rng
        )
    }

    static func probability<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let red = Int.random(in: 1...6, using: &rng)
        let blue = Int.random(in: 1...6, using: &rng)
        let green = Int.random(in: 1...6, using: &rng)
        let total = red + blue + green
        let notRed = blue + green
        let answer = Maths.fraction(notRed, total)
        let simplified = answer == "\(notRed)/\(total)" ? "" : " = \(answer)"

        return .build(
            topic: .probability,
            prompt: "A bag has \(red) red, \(blue) blue and \(green) green counters. One is picked at random. What is the probability it is not red?",
            answer: answer,
            candidates: [
                Maths.fraction(red, total),
                Maths.fraction(blue, total),
                Maths.fraction(green, total),
                Maths.fraction(notRed - 1, total),
                Maths.fraction(1, total),
                Maths.fraction(notRed, total + 1),
                Maths.fraction(notRed + 1, total + 1)
            ],
            explanation: "There are \(total) counters and \(blue) + \(green) = \(notRed) of them are not red, so P(not red) = \(notRed)/\(total)\(simplified).",
            using: &rng
        )
    }

    // MARK: Higher

    static func expandingBrackets<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let a = Int.random(in: 1...9, using: &rng)
        var b = Int.random(in: -9...9, using: &rng)
        while b == 0 || b == -a { b = Int.random(in: -9...9, using: &rng) }
        let answer = Maths.quadratic(a + b, a * b)

        return .build(
            topic: .expandingBrackets,
            prompt: "Expand and simplify \(Maths.bracket(a))\(Maths.bracket(b))",
            answer: answer,
            candidates: [
                Maths.quadratic(0, a * b),
                Maths.quadratic(a + b, -(a * b)),
                Maths.quadratic(a * b, a + b),
                Maths.quadratic(a - b, a * b),
                Maths.quadratic(a + b, a + b),
                Maths.quadratic(a + b, a * b + 1)
            ],
            explanation: "Multiply every term in the first bracket by every term in the second. x × x = x². The x terms are \(Maths.xTerm(a)) and \(Maths.xTerm(b)), which make \(Maths.xTerm(a + b)). The numbers multiply: \(a) × \(Maths.signed(b)) = \(Maths.signed(a * b)). So the answer is \(answer).",
            using: &rng
        )
    }

    static func pythagoras<G: RandomNumberGenerator>(_ rng: inout G) -> Question {
        let triples = [(3, 4, 5), (5, 12, 13), (6, 8, 10), (8, 15, 17), (9, 12, 15), (7, 24, 25), (12, 16, 20), (20, 21, 29)]
        let triple = triples.randomElement(using: &rng)!
        let (a, b, c) = triple

        return .build(
            topic: .pythagoras,
            prompt: "A right-angled triangle has shorter sides of \(a) cm and \(b) cm. How long is the hypotenuse?",
            answer: "\(c) cm",
            candidates: [
                "\(a + b) cm",
                "\(c * c) cm",
                "\(c + 1) cm",
                "\(c - 1) cm",
                "\(b - a) cm"
            ],
            explanation: "Use c² = a² + b²: \(a)² + \(b)² = \(a * a) + \(b * b) = \(c * c). Then c = √\(c * c) = \(c) cm.",
            using: &rng
        )
    }
}
