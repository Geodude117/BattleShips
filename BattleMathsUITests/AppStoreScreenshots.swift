import XCTest

/// Captures the App Store screenshots and saves them into the repo at
/// `docs/screenshots/iphone-6.9/` or `docs/screenshots/ipad-13/`.
///
/// Run it with the **Screenshots** scheme, once on an iPhone 16 Pro Max (6.9") simulator
/// and once on an iPad Pro 13-inch simulator. The normal BattleMaths scheme skips it.
final class AppStoreScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testCaptureScreenshots() throws {
        // 1. A battle in progress
        let battle = launch(scene: "battle")
        let aiming = battle.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tap enemy waters'")).firstMatch
        XCTAssertTrue(aiming.waitForExistence(timeout: 5))
        save("1-battle")

        // 2. A maths question
        let quiz = launch(scene: "question")
        let correct = quiz.buttons.matching(NSPredicate(format: "value == 'correct'")).firstMatch
        XCTAssertTrue(correct.waitForExistence(timeout: 5))
        save("2-question")

        // 3. The worked explanation after answering
        correct.tap()
        XCTAssertTrue(quiz.buttons["Fire away"].waitForExistence(timeout: 3))
        sleep(1) // let the highlight animation settle
        save("3-explanation")

        // 4. Placing the fleet
        let placing = XCUIApplication()
        placing.launch()
        let random = placing.buttons["Random fleet"]
        XCTAssertTrue(random.waitForExistence(timeout: 5))
        random.tap()
        sleep(1) // let the button's press animation finish
        save("4-placement")
    }

    // MARK: Helpers

    private func launch(scene: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-screenshots", scene]
        app.launch()
        return app
    }

    /// The repo's docs/screenshots/<device> folder, found from this source file's location on the Mac.
    private static let outputFolder: URL = {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad-13" : "iphone-6.9"
        return repoRoot.appending(path: "docs/screenshots/\(device)")
    }()

    @MainActor
    private func save(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        do {
            try FileManager.default.createDirectory(at: Self.outputFolder, withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: Self.outputFolder.appending(path: "\(name).png"))
        } catch {
            XCTFail("Couldn't save \(name).png to \(Self.outputFolder.path): \(error)")
        }
    }
}
