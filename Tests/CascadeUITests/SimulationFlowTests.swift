import XCTest

final class SimulationFlowTests: CascadeUITestCase {
    func testPlaybackDetonationAndRestartConfirmation() {
        enterSimulation()
        app.buttons["simulation.detonate"].tap()
        playback.tap()
        waitFor(element("metric.debris"), predicate: NSPredicate { object, _ in
            guard let element = object as? XCUIElement,
                  let value = element.value as? String,
                  let count = Int(value.replacingOccurrences(of: ",", with: "")) else { return false }
            return count > 0
        })
        playback.tap()
        XCTAssertEqual(playback.label, "Resume Simulation")
        let remaining = element("metric.satellites").value as? String
        XCTAssertNotEqual(remaining, "300")

        app.buttons["simulation.restart"].tap()
        cancelRestart()
        XCTAssertEqual(element("metric.satellites").value as? String, remaining)

        app.buttons["simulation.restart"].tap()
        app.buttons["Restart"].tap()
        waitForValue(element("metric.satellites"), "300")
        waitForValue(element("metric.debris"), "0")
        XCTAssertEqual(playback.label, "Resume Simulation")
    }

    func testPortraitPausesAndRestoresPlayingState() {
        enterSimulation()
        playback.tap()
        XCTAssertEqual(playback.label, "Pause Simulation")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(element("orientation.warning").waitForExistence(timeout: 10))
        XCTAssertFalse(playback.isEnabled)
        XCUIDevice.shared.orientation = .landscapeLeft
        waitForHittable(playback)
        XCTAssertEqual(playback.label, "Pause Simulation")
    }

    func testPortraitPreservesAnIntentionalPause() {
        enterSimulation()
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(element("orientation.warning").waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .landscapeRight
        waitForHittable(playback)
        XCTAssertEqual(playback.label, "Resume Simulation")
        waitForValue(element("metric.satellites"), "300")
    }

    func testBackgroundAndForegroundPreserveSession() {
        enterSimulation()
        openSettings()
        setToggle("Camera Control", isOn: false)
        closeSettings()
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForHittable(playback)
        XCTAssertFalse(app.buttons["onboarding.skip"].exists)
        XCTAssertEqual(playback.label, "Resume Simulation")
        openSettings()
        XCTAssertEqual(toggle("Camera Control").value as? String, "0")
    }
}
