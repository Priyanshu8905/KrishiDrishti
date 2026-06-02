// Tests/UITests.swift
// KrishiDrishti Tests — UI tests representing dashboard user flows and screen transitions

import XCTest

final class KrishiDrishtiUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testVerifyDashboardLayoutIsVisible() {
        // Assert header app title is present
        let navigationTitle = app.staticTexts["Krishi Drishti"]
        XCTAssertTrue(navigationTitle.exists)

        // Assert core tabs exist
        let fieldTabButton = app.tabBars.buttons["Field"]
        XCTAssertTrue(fieldTabButton.exists)

        let botTabButton = app.tabBars.buttons["KrishiBot"]
        XCTAssertTrue(botTabButton.exists)
    }

    func testNavigateToKrishiBotChat() {
        let botTabButton = app.tabBars.buttons["KrishiBot"]
        XCTAssertTrue(botTabButton.exists)
        botTabButton.tap()

        // Verify Bot chat welcomes user
        let botGreetings = app.staticTexts["👋 Hello! I am KrishiBot."]
        XCTAssertTrue(botGreetings.exists)

        // Test sending query
        let queryInput = app.textFields["Ask KrishiBot..."]
        if queryInput.exists {
            queryInput.tap()
            queryInput.typeText("What is early blight in tomato?")

            let sendButton = app.buttons["Send"]
            if sendButton.exists {
                sendButton.tap()
            }
        }
    }

    func testNavigateToProfileDetailsSheet() {
        let profileButton = app.buttons["person.crop.circle.fill"]
        XCTAssertTrue(profileButton.exists)
        profileButton.tap()

        // Authenticate dialog check (will trigger biometric simulator prompt)
        let bioPromptTitle = app.staticTexts["Profile Locked"]
        if bioPromptTitle.exists {
            let unlockButton = app.buttons["Unlock with Biometrics"]
            XCTAssertTrue(unlockButton.exists)
            unlockButton.tap()
        }
    }
}
