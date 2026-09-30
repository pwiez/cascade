import XCTest

@MainActor
class CascadeUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        app = XCUIApplication(bundleIdentifier: "pwiez.cascade")
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        guard app.buttons["onboarding.skip"].wait(for: \.isHittable, toEqual: true, timeout: 15) else {
            throw NSError(domain: "CascadeUITests", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Onboarding did not become ready after launch."])
        }
    }

    override func tearDown() async throws {
        guard let app else { return }
        if app.state != .notRunning {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.lifetime = .deleteOnSuccess
            add(screenshot)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "UI hierarchy"
            hierarchy.lifetime = .deleteOnSuccess
            add(hierarchy)
        }
        app.terminate()
        self.app = nil
    }

    var playback: XCUIElement { app.buttons["simulation.playback"] }
    var settingsForm: XCUIElement { element("settings.form") }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func enterSimulation() {
        app.buttons["onboarding.skip"].tap()
        waitForHittable(playback)
        waitForValue(element("metric.satellites"), "300")
        waitForValue(element("metric.debris"), "0")
        XCTAssertEqual(playback.label, "Resume Simulation")
    }

    func openSettings() {
        app.buttons["simulation.settings"].tap()
        waitForHittable(app.buttons["settings.done"])
    }

    func closeSettings() {
        app.buttons["settings.done"].tap()
        waitFor(app.buttons["settings.done"], predicate: NSPredicate(format: "hittable == false"))
    }

    func cancelRestart() {
        let cancel = app.buttons["Cancel"]
        if cancel.exists && cancel.isHittable {
            cancel.tap()
        } else {
            // iPad confirmation popovers dismiss when the user taps outside.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        }
        waitFor(app.buttons["Restart"], predicate: NSPredicate(format: "exists == false"))
    }

    func toggle(_ label: String) -> XCUIElement {
        app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
    }

    func setToggle(_ label: String, isOn: Bool) {
        let control = toggle(label)
        reveal(control)
        let expected = isOn ? "1" : "0"
        if control.value as? String != expected {
            // SwiftUI may expose the entire labeled row as a switch.
            let thumb = control.switches.firstMatch
            if thumb.exists {
                thumb.tap()
            } else {
                control.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            }
        }
        waitForValue(control, expected)
    }

    func slider(_ label: String) -> XCUIElement {
        app.sliders["settings.slider.\(label)"]
    }

    func reveal(_ element: XCUIElement, scrollingDown: Bool = true,
                file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<12 {
            var moveDown = scrollingDown
            if element.exists {
                let viewport = settingsForm.frame.insetBy(dx: 0, dy: 8)
                let frame = element.frame
                if !frame.isEmpty {
                    if viewport.contains(frame) && element.isHittable { return }
                    moveDown = frame.maxY > viewport.maxY
                }
            }
            // Scroll in the form's gutter so the gesture cannot drag a slider thumb.
            let start = settingsForm.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: moveDown ? 0.8 : 0.2))
            let end = settingsForm.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: moveDown ? 0.2 : 0.8))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Could not reveal \(element). Hierarchy:\n\(app.debugDescription)", file: file, line: line)
    }

    func waitForHittable(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.wait(for: \.isHittable, toEqual: true, timeout: 15),
                      "Control did not become hittable", file: file, line: line)
    }

    func waitForValue(_ element: XCUIElement, _ value: String,
                      file: StaticString = #filePath, line: UInt = #line) {
        waitFor(element, predicate: NSPredicate(format: "value == %@", value), file: file, line: line)
    }

    func waitFor(_ element: XCUIElement, predicate: NSPredicate,
                 file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed,
                       "Condition did not become true: \(predicate)", file: file, line: line)
    }
}
