import XCTest

final class OnboardingTests: CascadeUITestCase {
    func testNextBackAndEnter() {
        let advance = app.buttons["onboarding.advance"]
        XCTAssertEqual(advance.label, "Next")
        XCTAssertFalse(app.buttons["onboarding.back"].exists)

        advance.tap()
        waitForHittable(app.buttons["onboarding.back"])
        XCTAssertEqual(advance.label, "Enter the Cascade")
        app.buttons["onboarding.back"].tap()
        XCTAssertEqual(advance.label, "Next")

        advance.tap()
        advance.tap()
        waitForHittable(playback)
        XCTAssertFalse(app.buttons["onboarding.skip"].exists)
        XCTAssertEqual(playback.label, "Resume Simulation")
    }

    func testSwipesStopAtPageBoundaries() {
        let advance = app.buttons["onboarding.advance"]
        app.swipeRight()
        XCTAssertEqual(advance.label, "Next")
        app.swipeLeft()
        XCTAssertEqual(advance.label, "Enter the Cascade")
        app.swipeLeft()
        XCTAssertEqual(advance.label, "Enter the Cascade")
        app.swipeRight()
        XCTAssertEqual(advance.label, "Next")
    }

    func testSkipFromControlsAndFreshLaunch() {
        app.buttons["onboarding.advance"].tap()
        enterSimulation()
        app.terminate()
        app.launch()
        waitForHittable(app.buttons["onboarding.skip"])
        XCTAssertEqual(app.buttons["onboarding.advance"].label, "Next")
    }
}
