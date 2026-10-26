# Salvo Sums — iOS Project Plan

Oct 26, 2026 · @Geovan Inacay

## Overview

Salvo Sums (working title BattleMaths) is a single-player Battleships-style game for iPhone and iPad where every shot is earned by answering a GCSE maths question correctly. You play against a computer opponent, and v1 runs fully offline with no backend.

**Goals**

- Make GCSE maths practice feel like a game, not a worksheet.
- Teach through mistakes: every wrong answer shows a short worked explanation.
- Keep the game fair: the AI also has to "earn" its shots.

**In scope for v1**

- 10×10 grid, the classic five ships, drag-to-place with rotate.
- Eight GCSE question topics at Foundation and Higher levels.
- Three AI difficulty levels.
- Per-topic accuracy stats saved on device.

**Out of scope for v1**

- Multiplayer, accounts, leaderboards, in-app purchases, Android.

## Tech stack and project structure

The app is SwiftUI targeting iOS 17 or later. All game logic lives in a local Swift package with no UI imports, so it can be tested in isolation.

| Concern | Choice | Why |
| --- | --- | --- |
| UI | SwiftUI, `Grid`, `DragGesture` | Native, quick to build a tappable 10×10 board |
| State | `@Observable` view model + state enum | Keeps logic out of views |
| Persistence | SwiftData | Per-topic accuracy and game history |
| Randomness | `SeededGenerator` (SplitMix64) in BattleEngine | Seeded, so tests are repeatable; no GameplayKit dependency |
| Feedback | `.sensoryFeedback`, AVFoundation | Haptics and sound on hit, miss, sink |
| Tests | Swift Testing (engine), XCUITest (flows) | Fast unit tests plus end-to-end checks |

```
BattleMaths/
├── BattleMaths (app target)
│   ├── App/            BattleMathsApp.swift
│   ├── Views/          HomeView, PlacementView, GameView,
│   │                   BoardView, CellView, QuestionSheet, ResultsView
│   ├── Components/     FractionView, AnswerButton, AmmoCounter
│   ├── ViewModels/     GameViewModel
│   └── Persistence/    TopicStats, GameRecord
└── Packages/
    └── BattleEngine
        ├── Model/      Coordinate, Ship, ShipType, Board, ShotResult
        ├── Game/       GameState, AmmoLedger, Rules
        ├── AI/         Opponent protocol, RandomAI, HuntTargetAI, ProbabilityAI
        ├── Questions/  Question, QuestionGenerator protocol, generators per topic
        └── Tests/
```

The game flow is a state machine in the view model: `placing → needsAmmo → answering → aiming → resolving → aiTurn → needsAmmo …`, ending in `won` or `lost`.

## Game rules and ammo economy

One correct answer earns one shot; harder questions and streaks earn more. Each turn, the player answers a question, then fires whatever ammo they have, then the AI takes its turn.

**Board and fleet**

- 10×10 grid, columns A–J and rows 1–10.
- Carrier (5), Battleship (4), Cruiser (3), Submarine (3), Destroyer (2).
- Ships can't overlap or extend past the grid edge. Adjacent placement is allowed.

**Earning ammo**

| Event | Reward |
| --- | --- |
| Correct Foundation answer | 1 shot |
| Correct Higher answer | 2 shots |
| 3 correct in a row | +1 bonus shot |
| 5 correct in a row | Unlock one special weapon |
| Wrong answer | No ammo, worked explanation shown |

**Special weapons** (one at a time, unlocked by streaks)

- **Sonar:** reveals whether any ship is inside a 3×3 area, without firing.
- **Airstrike:** fires on all five cells of a plus shape.

**AI fairness**

The AI "answers" too, using a hidden accuracy rate: 60% on Easy, 75% on Medium, 90% on Hard. A miss means it loses that turn's shot. This keeps the race even and makes the player's accuracy matter.

**Winning**

Sink all five enemy ships before the AI sinks yours.

## Question engine

Questions are generated in code, not stored in a fixed bank, so they never run out and the correct answer is always computed. Wrong options come from common student mistakes, which makes the multiple choice actually test understanding.

**How a generator works**

1. Pick random values within sensible bounds, using the seeded random source.
2. Compute the correct answer.
3. Build three distractors from named misconceptions.
4. Remove duplicates, shuffle the four options, and attach a short worked explanation.

```swift
protocol QuestionGenerator {
    var topic: Topic { get }
    func make(tier: Tier, rng: GKRandom) -> Question
}

struct Question {
    let topic: Topic
    let tier: Tier            // .foundation or .higher
    let prompt: MathText      // text with fractions/powers
    let options: [MathText]   // exactly 4
    let correctIndex: Int
    let explanation: String
}
```

**v1 topics**

| Topic | Example | Distractors from |
| --- | --- | --- |
| Fractions | 2/3 + 1/4 | Adding tops and bottoms (3/7), wrong common denominator |
| Percentages | Increase £80 by 15% | Adding 15 instead of 15% (£95), finding only the 15% (£12) |
| Ratio | Share £60 in ratio 2:3 | Splitting 60 by 2 and 3, swapping the parts |
| Linear equations | 3x + 5 = 20 | Sign error (x = 25/3), forgetting to divide (x = 15) |
| Expanding brackets | (x + 3)(x − 2) | Missing the middle term, sign error on the constant |
| Area and volume | Area of a triangle, base 8, height 5 | Forgetting to halve (40), adding the sides |
| Pythagoras | Hypotenuse of 6 and 8 | Adding the sides (14), forgetting the square root (100) |
| Probability | P(not red) from a bag | Giving P(red), using the wrong total |

**Adaptive selection**

Pick the next topic weighted towards the ones the player gets wrong most, using SwiftData accuracy stats. Keep some randomness so strong topics still come up.

## AI opponent

Three difficulty levels map to three targeting strategies, each paired with a hidden answer accuracy. All of them sit behind one `Opponent` protocol, so the game doesn't care which is playing.

| Level | Targeting | Answer accuracy |
| --- | --- | --- |
| Easy | Random cells it hasn't tried | 60% |
| Medium | Hunt/target: random until a hit, then probes neighbours along the line | 75% |
| Hard | Probability density: scores every cell by how many remaining ship placements could cover it, fires at the highest | 90% |

```swift
protocol Opponent {
    mutating func placeFleet(rng: GKRandom) -> [Ship]
    mutating func nextShot(knowledge: TargetingBoard, rng: GKRandom) -> Coordinate
    mutating func record(_ result: ShotResult, at: Coordinate)
}
```

The AI only sees what a player would see: hits, misses and sunk ships. It never reads the player's board directly.

## Milestones

The build runs in six phases, engine first, so each phase ends with something testable.

**Phase 0 — Repo and project setup**

- [x] Create the Xcode project (SwiftUI, iOS 17, iPhone + iPad) in this repo
- [x] Add a Swift `.gitignore` and a README with the game concept
- [x] Create the local `BattleEngine` Swift package and link it to the app target
- [x] Set up a test plan with Swift Testing for the package

**Phase 1 — Core engine**

- [x] `Coordinate`, `ShipType`, `Ship`, `Board` models
- [x] Placement validation (in bounds, no overlap) and random fleet placement
- [x] Shot resolution: miss, hit, sunk, already-fired
- [x] Win detection
- [x] `AmmoLedger` with streaks and bonus rules

**Phase 2 — Question engine**

- [x] `Question`, `Topic`, `Tier` types and `QuestionBank` generators (proper `MathText` rendering still to do)
- [x] Fractions and Percentages generators first, with misconception distractors
- [x] Remaining six topic generators
- [ ] Adaptive topic picker using accuracy weights

**Phase 3 — AI opponent**

- [x] `AIStrategy` with random targeting
- [x] Hunt/target strategy
- [ ] `ProbabilityAI`
- [x] Hidden answer accuracy per difficulty

**Phase 4 — Playable UI**

- [x] Board view with tappable cells (hit, miss, sunk states)
- [x] Ship placement screen with tap to place, rotate and move
- [x] Question sheet with four answer buttons and worked explanation
- [x] `GameViewModel` state machine wiring the full turn loop
- [x] Results screen (separate home screen still to do)

**Phase 5 — Polish and progress**

- [ ] Haptics, sounds and hit/sink animations (haptics and sounds done; animations still to do)
- [ ] SwiftData stats: accuracy per topic, games won
- [x] Special weapons (Sonar, Airstrike)
- [ ] `FractionView` and superscript rendering for powers
- [ ] TestFlight build

## Testing

Most tests live in the `BattleEngine` package and run in seconds without a simulator. Seeded randomness makes every game, question and AI shot reproducible.

| Layer | Tool | What it checks |
| --- | --- | --- |
| Engine rules | Swift Testing | Placement, shot results, sinking, win detection, ammo and streaks |
| Question generators | Swift Testing, parameterised over 1,000 seeds | Exactly 4 unique options, correct answer present once, answer verified independently, no negative or undefined values |
| AI | Swift Testing | Never fires the same cell twice; Hard beats Easy in average shots to win over 500 simulated games |
| View model | Swift Testing | State machine transitions: no firing without ammo, AI turn follows player turn |
| UI flows | XCUITest | Place fleet → answer → fire → hit; full game to the results screen |

The generator tests matter most: a maths game that marks a correct answer wrong loses trust immediately.

## Risks and open questions

The biggest risk is the question engine: wrong answers or confusing wording will break the learning side faster than any game bug.

| Risk | Mitigation |
| --- | --- |
| Generated questions have wrong or duplicate answers | Seed-sweep tests; verify each answer by a second method |
| Pacing feels slow if every shot needs a question | Higher-tier and streak bonuses give multiple shots per question |
| Maths notation looks poor as plain text | Build `FractionView` and superscripts early, in Phase 4 |
| Hard AI feels unbeatable | Tune hidden accuracy rates after playtesting |

**Open questions**

- [ ] Should there be a timer per question for bonus ammo, or is that too stressful?
- [ ] Should players pick Foundation or Higher, or should difficulty adapt automatically?
- [ ] Should wrong answers cost anything beyond a lost shot?

**Later ideas**

- Game Center achievements and leaderboards.
- A topic-practice mode outside the game.
- Two-player pass-and-play on one iPad.
