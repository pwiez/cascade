# Cascade

Cascade is my winning submission for Apple's 2026 Swift Student Challenge. It's an iPad app that simulates Kessler Syndrome, the chain reaction where one collision in orbit creates debris that causes more collisions. You can detonate satellites or wait for them to crash on their own, and watch how far the cascade spreads. There's also a built-in explainer tab covering the details and the science behind it all.

## See more

- More info and screenshots: [pedrowiezel.com/en/showcase/cascade](https://pedrowiezel.com/en/showcase/cascade/)
- Demo video: [media.pedrowiezel.com/cascade_demo.mp4](https://media.pedrowiezel.com/cascade_demo.mp4)

## Running it

Clone the repo and open `Cascade.swiftpm` in Swift Playgrounds on iPad, or in Xcode on the Mac. Minimum SDK is iOS 18.0. Then run it on an iPad or the simulator.

```bash
git clone https://github.com/pwiez/cascade.git
open cascade/Cascade.swiftpm
```

## Layout

The package has three targets. `AppModule` (`App/`) is the SwiftUI layer, `CascadeEngine` (`Engine/`) is the simulation, and nothing in the engine imports SwiftUI's view layer — the boundary is enforced by the module, not by convention. Splitting them is also what makes the engine testable, since an `.iOSApplication` executable target can't be.

```
App/     SwiftUI views, screens and design tokens
Engine/  Core/       shared constants, RNG, buffers
         State/      settings, scenario, the observable façade
         Scene/      RealityKit scene controller and physics solver
         Mechanics/  debris pool and spatial grid
         Visuals/    camera rig and debris batching
Tests/   engine regression and invariant tests
```

## Tests

The engine's numeric core is deterministic and UI-free, so it's covered by unit tests. Swift Playgrounds doesn't run them; use Xcode, or:

```bash
xcodebuild test -scheme Cascade -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'
```

## Credits

The simulation and explainer draw on public research and reports from NASA and the ESA Space Debris Office. Earth textures by [Tom Patterson](https://shadedrelief.com/natural3/) and [Solar System Scope](https://www.solarsystemscope.com), both based on NASA imaging.

## License

Copyright © 2026 Pedro Wiezel. All rights reserved. The source is publicly viewable for reference only — it is **not** open source. You may read it, but no rights are granted to use, copy, modify, redistribute, or sell it (commercially or otherwise) without my written permission. See [LICENSE](LICENSE). The bundled Earth textures stay under their original creators' terms.
