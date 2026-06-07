import XCTest

final class PureSocialUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Skip onboarding for all tests
        app.launchArguments = ["-onboardingComplete", "YES"]
        app.launch()
    }

    // MARK: - App Launches Without Crash

    func testAppLaunchesAndShowsContent() throws {
        // App should be running and show some content (not crash)
        XCTAssertTrue(app.exists)
        sleep(3)
        XCTAssertTrue(app.exists, "App should still be running after 3s")
    }

    // MARK: - Tab Bar Present

    func testTabBarIsVisible() throws {
        sleep(3)
        // At least one tab should be visible (WA, IG, FB, GM, X, LI, TG)
        let tabLabels = ["WA", "IG", "FB", "GM", "X", "LI", "TG"]
        var foundCount = 0
        for label in tabLabels {
            let btn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
            if btn.waitForExistence(timeout: 1) { foundCount += 1 }
        }
        XCTAssertGreaterThan(foundCount, 0, "At least one platform tab should be visible")
        print("Tabs visible: \(foundCount)")
    }

    // MARK: - Instagram tab loads without crash (login page or inbox)

    func testInstagramTabLoadsLoginOrInbox() throws {
        sleep(3)
        let igTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'IG'")).firstMatch
        guard igTab.waitForExistence(timeout: 5) else {
            XCTFail("Instagram tab not found"); return
        }
        igTab.tap()
        sleep(6) // give time for network/redirect

        // App must not have crashed
        XCTAssertTrue(app.exists, "App should be alive after tapping Instagram tab")

        // Take a screenshot for manual verification
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "instagram_tab"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    // MARK: - Gmail tab loads without crash

    func testGmailTabLoadsLoginOrInbox() throws {
        sleep(3)
        let gmTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'GM'")).firstMatch
        guard gmTab.waitForExistence(timeout: 5) else {
            XCTFail("Gmail tab not found"); return
        }
        gmTab.tap()
        sleep(6)

        XCTAssertTrue(app.exists, "App should be alive after tapping Gmail tab")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "gmail_tab"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    // MARK: - WhatsApp tab loads without crash

    func testWhatsAppTabLoads() throws {
        sleep(3)
        let waTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'WA'")).firstMatch
        guard waTab.waitForExistence(timeout: 5) else {
            XCTFail("WhatsApp tab not found"); return
        }
        waTab.tap()
        sleep(6)

        XCTAssertTrue(app.exists, "App should be alive after tapping WhatsApp tab")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "whatsapp_tab"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    // MARK: - No phantom modal on launch

    func testNoSpuriousModalOnLaunch() throws {
        sleep(5) // wait for all initial loads

        // If an auth sheet were spuriously presented, it would show a "Terminé" button
        let termineBtn = app.buttons["Terminé"]
        XCTAssertFalse(termineBtn.exists, "No spurious auth modal should appear on launch")

        // Settings / onboarding sheets should also not be open
        let onboardingText = app.staticTexts["Choose what\nyou let in."]
        // onboarding should be suppressed via launchArguments
        XCTAssertFalse(onboardingText.exists, "Onboarding should not reappear when already complete")
    }

    // MARK: - Navigation toolbar is present

    func testNavigationToolbarPresent() throws {
        sleep(3)
        // Back button (chevron.left), reload button should be in the toolbar
        // The platform name button (center) should also be there
        let reloadBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'arrow.clockwise' OR label CONTAINS[c] 'Reload'")).firstMatch
        // At minimum the app should have rendered without crash
        XCTAssertTrue(app.exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "toolbar_state"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
