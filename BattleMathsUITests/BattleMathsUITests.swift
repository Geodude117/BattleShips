import XCTest

final class BattleMathsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsTitle() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["BattleMaths"].waitForExistence(timeout: 5))
    }
}
