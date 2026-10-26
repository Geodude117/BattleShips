import XCTest

final class BattleMathsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchStartsWithFleetPlacement() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["BattleMaths"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Place your fleet"].exists)
        XCTAssertFalse(app.buttons["Start battle"].isEnabled, "Can't start until every ship is placed")
    }

    @MainActor
    func testPlacingShipsByHand() throws {
        let app = XCUIApplication()
        app.launch()

        // Carrier (5) across row 1, then each ship on its own row underneath.
        for row in 1...5 {
            app.buttons["player-A\(row)"].tap()
        }
        XCTAssertTrue(app.buttons["Start battle"].isEnabled, "All five ships should now be placed")

        // Tapping a placed ship picks it up again.
        app.buttons["player-B1"].tap()
        XCTAssertFalse(app.buttons["Start battle"].isEnabled)

        // Put it back vertically down column J.
        app.buttons["rotate"].tap()
        app.buttons["player-J1"].tap()
        XCTAssertTrue(app.buttons["Start battle"].isEnabled)
        XCTAssertEqual(app.buttons["player-J5"].value as? String, "Ship")

        app.buttons["Start battle"].tap()
        XCTAssertTrue(app.buttons["Answer a question to load ammo"].waitForExistence(timeout: 3))
    }

    /// Plays several full rounds: answer a question, fire any ammo earned, then wait for the enemy's turn.
    @MainActor
    func testPlayingSeveralRounds() throws {
        let app = XCUIApplication()
        app.launch()
        startWithRandomFleet(app)

        let ask = app.buttons["Answer a question to load ammo"]
        let aimingPrompt = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tap enemy waters'")).firstMatch
        let columns = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        var nextCell = 0

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
                }
            } else {
                carryOn.tap()
            }

            XCTAssertTrue(ask.waitForExistence(timeout: 5), "Turn did not come back to the player after round \(round)")
        }

        // Six rounds can't finish a game, so it must still be in progress.
        XCTAssertFalse(app.staticTexts["You win!"].exists)
        XCTAssertFalse(app.staticTexts["You lost this one."].exists)
    }

    @MainActor
    func testNewGameGoesBackToPlacement() throws {
        let app = XCUIApplication()
        app.launch()
        startWithRandomFleet(app)

        app.buttons["Game options"].tap()
        let newGame = app.buttons["New game"]
        XCTAssertTrue(newGame.waitForExistence(timeout: 3))
        newGame.tap()

        XCTAssertTrue(app.staticTexts["Place your fleet"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Start battle"].isEnabled)
    }

    @MainActor
    private func startWithRandomFleet(_ app: XCUIApplication) {
        let random = app.buttons["Random fleet"]
        XCTAssertTrue(random.waitForExistence(timeout: 5))
        random.tap()
        app.buttons["Start battle"].tap()
        XCTAssertTrue(app.buttons["Answer a question to load ammo"].waitForExistence(timeout: 3))
    }
}
