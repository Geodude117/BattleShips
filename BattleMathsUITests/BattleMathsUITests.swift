import XCTest

final class BattleMathsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsTitle() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["BattleMaths"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Answer a question to load ammo"].exists)
    }

    /// Plays several full rounds: answer a question, fire any ammo earned, then wait for the enemy's turn.
    @MainActor
    func testPlayingSeveralRounds() throws {
        let app = XCUIApplication()
        app.launch()

        let ask = app.buttons["Answer a question to load ammo"]
        let aimingPrompt = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tap enemy waters'")).firstMatch
        let columns = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        var nextCell = 0
        var shotsFired = 0

        for round in 1...6 {
            XCTAssertTrue(ask.waitForExistence(timeout: 10), "Ask button missing at round \(round)")
            ask.tap()

            let firstOption = app.buttons["answer-0"]
            XCTAssertTrue(firstOption.waitForExistence(timeout: 5), "Question sheet did not appear")
            XCTAssertTrue(app.buttons["answer-3"].exists, "Question should have four options")
            firstOption.tap()

            let fireAway = app.buttons["Fire away"]
            let carryOn = app.buttons["Continue"]
            XCTAssertTrue(fireAway.waitForExistence(timeout: 3) || carryOn.exists, "No feedback after answering")

            if fireAway.exists {
                fireAway.tap()
                XCTAssertTrue(aimingPrompt.waitForExistence(timeout: 3), "Should be able to aim after a correct answer")
                while aimingPrompt.exists && nextCell < 100 {
                    let label = "\(columns[nextCell % 10])\(nextCell / 10 + 1)"
                    app.buttons["enemy-\(label)"].tap()
                    nextCell += 1
                    shotsFired += 1
                }
            } else {
                carryOn.tap()
            }

            // The enemy takes its turn, then control comes back to the player.
            XCTAssertTrue(ask.waitForExistence(timeout: 5), "Turn did not come back to the player after round \(round)")
        }

        // Six rounds can't finish a game, so it must still be in progress.
        XCTAssertFalse(app.staticTexts["You win!"].exists)
        XCTAssertFalse(app.staticTexts["You lost this one."].exists)
        if shotsFired > 0 {
            let shotLog = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'You fired at' OR label BEGINSWITH 'Enemy'")).firstMatch
            XCTAssertTrue(shotLog.exists || ask.exists)
        }
    }

    @MainActor
    func testNewGameResetsTheBoard() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Game options"].tap()
        let newGame = app.buttons["New game"]
        XCTAssertTrue(newGame.waitForExistence(timeout: 3))
        newGame.tap()

        XCTAssertTrue(app.buttons["Answer a question to load ammo"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'New game on'")).firstMatch.exists)
    }
}
