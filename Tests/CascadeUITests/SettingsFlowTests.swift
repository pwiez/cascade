import XCTest

final class SettingsFlowTests: CascadeUITestCase {
    func testLiveTogglesPersistWhenClosingThePanel() {
        enterSimulation()
        openSettings()
        for label in ["Camera Control", "Debris Rotation", "Full Lighting"] {
            setToggle(label, isOn: label == "Full Lighting")
        }
        closeSettings()
        openSettings()
        XCTAssertEqual(toggle("Camera Control").value as? String, "0")
        XCTAssertEqual(toggle("Debris Rotation").value as? String, "0")
        XCTAssertEqual(toggle("Full Lighting").value as? String, "1")
        XCTAssertFalse(app.staticTexts["Restart Pending"].exists)
    }

    func testVisibilityAndStatisticsControls() {
        enterSimulation()
        openSettings()
        app.buttons["Visibility"].tap()
        for label in ["Show Earth", "Show Satellites", "Show Debris", "Show Simulation Stats"] {
            setToggle(label, isOn: false)
        }
        closeSettings()
        XCTAssertFalse(element("metric.satellites").exists)
        XCTAssertFalse(element("metric.debris").exists)
        openSettings()
        setToggle("Show Simulation Stats", isOn: true)
        closeSettings()
        waitForValue(element("metric.satellites"), "300")
    }

    func testScenarioChangesWaitForConfirmedRestart() throws {
        enterSimulation()
        openSettings()
        let count = slider("Initial Satellites")
        reveal(count)
        count.adjust(toNormalizedSliderPosition: 1)
        waitFor(count, predicate: NSPredicate(format: "value != '300'"))
        let requested = try XCTUnwrap(count.value as? String)
        let requestedCount = try XCTUnwrap(Int(requested))
        XCTAssertTrue((200...500).contains(requestedCount))
        XCTAssertEqual(requestedCount % 25, 0)
        XCTAssertTrue(app.staticTexts["Restart Pending"].exists)
        XCTAssertEqual(element("metric.satellites").value as? String, "300")

        let apply = app.buttons["settings.restart"]
        reveal(apply)
        apply.tap()
        cancelRestart()
        XCTAssertEqual(element("metric.satellites").value as? String, "300")
        apply.tap()
        app.buttons["Restart"].tap()
        waitForValue(element("metric.satellites"), requested)
        reveal(count, scrollingDown: false)
        waitForValue(count, requested)
        XCTAssertFalse(app.staticTexts["Restart Pending"].exists)
        closeSettings()
        XCTAssertEqual(playback.label, "Resume Simulation")
    }

    func testResetDefaultsRestoresControlsAndDiscardsPendingScenario() {
        enterSimulation()
        openSettings()
        setToggle("Camera Control", isOn: false)
        setToggle("Full Lighting", isOn: true)
        let inclination = toggle("Randomize Orbital Planes")
        setToggle("Randomize Orbital Planes", isOn: false)
        let count = slider("Initial Satellites")
        reveal(count, scrollingDown: false)
        count.adjust(toNormalizedSliderPosition: 1)
        let reset = app.buttons["settings.resetDefaults"]
        reveal(reset)
        reset.tap()
        reveal(count, scrollingDown: false)
        waitForValue(count, "300")
        XCTAssertFalse(app.staticTexts["Restart Pending"].exists)
        let camera = toggle("Camera Control")
        reveal(camera, scrollingDown: false)
        XCTAssertEqual(camera.value as? String, "1")
        XCTAssertEqual(toggle("Full Lighting").value as? String, "0")
        reveal(inclination)
        XCTAssertEqual(inclination.value as? String, "1")
        closeSettings()
        waitForValue(element("metric.satellites"), "300")
        XCTAssertEqual(playback.label, "Resume Simulation")
    }

    func testPhysicsAndSpreadSlidersUpdateWithoutRestart() {
        enterSimulation()
        openSettings()
        for label in ["Time Scale", "Debris Ejection Force", "Satellite Collision Radius",
                      "Debris per Collision", "Max Debris Count", "Debris Removal Distance"] {
            changeSlider(label)
        }
        let spread = app.buttons["Advanced Debris Spread"]
        reveal(spread)
        spread.tap()
        for label in ["Tangential (Velocity)", "Radial (Altitude)", "Normal (Inclination)"] {
            changeSlider(label)
        }
        reveal(slider("Initial Satellites"), scrollingDown: false)
        XCTAssertFalse(app.staticTexts["Restart Pending"].exists)
        closeSettings()
        XCTAssertEqual(playback.label, "Resume Simulation")
    }

    func testScaleControlsAndWarning() {
        enterSimulation()
        openSettings()
        app.buttons["Colors & Scaling"].tap()
        let satellites = slider("Satellite Scale")
        reveal(satellites)
        satellites.adjust(toNormalizedSliderPosition: 1)
        XCTAssertTrue(app.staticTexts["Visual scale exceeds collision radius. Objects may overlap visually."].exists)
        satellites.adjust(toNormalizedSliderPosition: 0)
        XCTAssertFalse(app.staticTexts["Visual scale exceeds collision radius. Objects may overlap visually."].exists)
        changeSlider("Debris Scale")
    }

    private func changeSlider(_ label: String) {
        let control = slider(label)
        reveal(control)
        let initial = control.value as? String
        XCTAssertNotNil(initial)
        control.adjust(toNormalizedSliderPosition: 0.85)
        waitFor(control, predicate: NSPredicate(format: "value != %@", initial ?? ""))
    }
}
