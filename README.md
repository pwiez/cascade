# Cascade

Cascade is my winning submission for Apple's 2026 Swift Student Challenge. It's an iPad app that simulates Kessler Syndrome: collisions in orbit create debris, which can cause more collisions.

You can detonate satellites or wait for them to collide, then watch how far the cascade spreads. The Learn More tab explains orbits, collisions, and the risks of space debris.

[More about Cascade](https://pedrowiezel.com/en/showcase/cascade/) · [Watch the demo](https://media.pedrowiezel.com/cascade_demo.mp4)

## Local development

Cascade requires **iPadOS 26.0 or later**. On a Mac, open the package in Xcode, choose an iPad simulator or connected iPad, and run it:

```bash
git clone https://github.com/pwiez/cascade.git
cd cascade
open Cascade.swiftpm
```

You can also open `Cascade.swiftpm` in Swift Playgrounds on an iPad. Use landscape orientation; the simulation pauses in portrait.

## Code layout

The package has three targets: `AppModule` for the SwiftUI interface, `CascadeEngine` for physics and RealityKit rendering, and `CascadeEngineTests` for engine tests.

```text
App/     SwiftUI views, screens and design tokens
Engine/  Core/       constants, random generator, frame buffers and task queue
         State/      settings, scenario and observable simulation state
         Scene/      scene controller, satellite creation and physics solver
         Mechanics/  debris pool and spatial grid
         Visuals/    camera and debris rendering
Tests/   engine tests
```

Scenario edits stay in `Simulation.draft` until a restart applies them. `SceneController` passes commands and frames through `SimulationWorkQueue` so a reset waits for an in-flight physics step. The solver runs on its own serial executor. Each returned frame stays unchanged while the solver prepares later frames, and the renderer uploads and draws only active debris.

## Tests

The local suite combines engine tests with UI tests for onboarding, simulation controls, settings, orientation changes, and Learn More. Use an iPad simulator running iPadOS 26 or later. From the repository root:

```bash
xcrun simctl list devices available
./scripts/test.sh all <IPAD_SIMULATOR_UDID>
```

Use `unit` or `ui` in place of `all` to run one suite. The script prints a summary and the path to its logs and result bundles. Engine runs also collect code coverage. It leaves an already-booted simulator running and shuts down one it boots itself. See [Testing](docs/TESTING.md) for coverage, Xcode usage, and manual checks. Swift Playgrounds doesn't run the test targets.

## Credits

The simulation and Learn More chapters draw on research and reports from NASA and the ESA Space Debris Office. The app's Sources & Credits chapter lists the references.

Earth textures are by [Tom Patterson](https://shadedrelief.com/natural3/) and [Solar System Scope](https://www.solarsystemscope.com/textures/), based on NASA imaging.

## License

Copyright © 2026 Pedro Wiezel. All rights reserved.

The source is available to read for reference. Using, copying, modifying, redistributing, or selling it requires my written permission; see [LICENSE](LICENSE) for the full terms. The Earth textures remain under their creators' terms.
