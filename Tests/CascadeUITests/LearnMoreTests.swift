import XCTest

final class LearnMoreTests: CascadeUITestCase {
    func testEveryChapterAndScrollReset() {
        enterSimulation()
        app.buttons.matching(identifier: "Learn More").firstMatch.tap()
        let chapters = [
            ("hero", "What is Kessler Syndrome?"),
            ("orbits", "How Orbits Work"),
            ("mechanics", "Chain Reaction"),
            ("situation", "Current Situation"),
            ("remediation", "Remediation"),
            ("glossary", "Glossary"),
            ("about", "About Cascade"),
            ("credits", "Sources & Credits")
        ]
        for (identifier, title) in chapters {
            let row = app.buttons["learnMore.\(identifier)"]
            waitForHittable(row)
            row.tap()
            let heading = element("learnMore.chapterTitle")
            waitFor(heading, predicate: NSPredicate(format: "hittable == true AND label BEGINSWITH %@", title))
            app.scrollViews["learnMore.chapter"].swipeUp()
        }
        app.buttons["learnMore.glossary"].tap()
        let heading = element("learnMore.chapterTitle")
        waitFor(heading, predicate: NSPredicate(format: "hittable == true AND label BEGINSWITH 'Glossary'"))
        let chapter = app.scrollViews["learnMore.chapter"]
        for _ in 0..<5 {
            chapter.swipeUp()
            if !heading.isHittable { break }
        }
        XCTAssertFalse(heading.isHittable)
        app.buttons["learnMore.orbits"].tap()
        waitFor(heading, predicate: NSPredicate(format: "hittable == true AND label BEGINSWITH 'How Orbits Work'"))
        app.buttons.matching(identifier: "Simulation").firstMatch.tap()
        waitForHittable(playback)
        XCTAssertEqual(playback.label, "Resume Simulation")
        waitForValue(element("metric.satellites"), "300")
    }
}
