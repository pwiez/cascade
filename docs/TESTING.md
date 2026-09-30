# Testing Cascade

Run tests on a Mac with Xcode and an available iPad simulator running iPadOS 26 or later. The runner uses Xcode's command-line tools and Python 3 to read result summaries; it requires no additional packages.

## Run the suite

Choose a simulator by its UDID, then run from the repository root:

```bash
xcrun simctl list devices available
./scripts/test.sh all <IPAD_SIMULATOR_UDID>
```

`all` is the default. To keep the destination in your shell environment:

```bash
export DESTINATION_ID=<IPAD_SIMULATOR_UDID>
./scripts/test.sh unit
./scripts/test.sh ui
./scripts/test.sh
```

The script boots the selected device if needed and waits for it to become ready. It preserves an
already-booted simulator and shuts down a simulator it started, including after a failure or
interruption. UI runs build and install Cascade, then terminate both the test app and UI runner
during cleanup. Test parallelization across simulators is disabled so the UI runner uses the device
where the app was installed. Xcode's UI test timeouts are enabled with a default allowance of 180
seconds and a maximum of 240 seconds.

Each invocation creates a separate directory under `/tmp/cascade-tests.*`. Build logs, test logs, derived data, and `.xcresult` bundles stay there for inspection. The script prints that path and returns a nonzero exit status if a build, test, or result-summary check fails. In `all` mode, a failed unit suite does not prevent the UI suite from running.

## What the tests cover

| Suite | Scope |
| --- | --- |
| `CascadeEngineTests` | Debris integration and removal, collision detection, spatial indexing, random-number invariants, settings, simulation state and command forwarding, cancellation ordering, frame ownership, satellite geometry, camera targets, and debris mesh uploads. |
| `CascadeUITests` | Onboarding navigation, playback and detonation, restart confirmation, settings and pending scenario changes, visibility controls, portrait handling, background/foreground state, and Learn More navigation. |

Engine tests live in `Cascade.swiftpm/Tests/CascadeEngineTests` and use Swift Testing. UI tests live
in `Tests/CascadeUITests` and use XCTest. Their separate Xcode project launches the installed
Cascade app through
[`XCUIApplication(bundleIdentifier:)`](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/init%28bundleidentifier%3A%29),
using `pwiez.cascade`. Each UI test starts a fresh app session in landscape with English labels.
When the app is still running, failed UI tests attach a screenshot and element hierarchy to their
result bundle.

The unit run enables code coverage. Open `unit.xcresult` in Xcode to inspect it, or export the report:

```bash
xcrun xccov view --report --json /tmp/cascade-tests.<RUN>/unit.xcresult
```

Coverage shows which code executed. It does not measure the quality of assertions or establish visual correctness. UI coverage is not included in the unit report. Use each run's result bundle for the current test count and outcome; parameterized tests can produce several cases from one declaration.

## Run from Xcode

Open `Cascade.swiftpm`, select the **Cascade** scheme and an iPad simulator, then choose **Product > Test** for engine tests.

For UI tests, first build and run Cascade on that same simulator. Open `Tests/CascadeUITests.xcodeproj`, select **CascadeUITests**, and choose **Product > Test**. Keep parallel testing disabled because the app is installed on the selected device. The local script handles the app build and installation automatically.

## Checks that still need observation

Simulator assertions verify controls and state. They do not approve the app's appearance. Inspect layout, colors, Earth textures, lighting, camera transitions, and dense debris scenes before accepting visual changes. Camera unit tests check target transforms without waiting for animation playback; UI screenshots are failure evidence, not an image-comparison baseline.

Use a physical iPad to check frame pacing, sustained simulation load, touch interaction, and rotation on the target hardware. A passing simulator run does not establish those results.

## Adding tests

Put a regression beside the behavior it protects. Use deterministic inputs for physics comparisons and invariants for random orbital directions. Queue tests control suspension explicitly, and UI tests wait for observable state rather than fixed delays. Keep simulator destinations explicit and retain failing result bundles for diagnosis.

Add new UI test files to the `CascadeUITests` target in Xcode. Swift Package Manager discovers engine test files inside `Cascade.swiftpm/Tests/CascadeEngineTests`.
