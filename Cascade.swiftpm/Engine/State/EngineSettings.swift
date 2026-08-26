//
//  EngineSettings.swift
//  Cascade
//

/// Everything the engine needs to run a frame, resolved from authored state.
///
/// This exists to keep one rule honest: values the user *authored* and values
/// the engine *derives* are different things, and only the authored ones belong
/// in stored state. `Simulation` stores ``SimSettings`` and ``Scenario``; every
/// derivation — unit conversions, the hitbox correction — happens here, once, on
/// the way out.
///
/// Nesting rather than flattening is deliberate: `sim` can change on any frame,
/// `scenario` only changes when the universe is rebuilt, and reading
/// `settings.scenario.orbitAltitude` says so at the use site.
struct EngineSettings: Sendable {

    /// Live tunables, exactly as the user set them.
    let sim: SimSettings

    /// The scenario the running universe was built from.
    let scenario: Scenario

    /// Collision radius grown to track the satellites' visual scale, so that
    /// scaling a satellite up doesn't leave its hitbox rattling around inside
    /// the cube the user can see.
    let effectiveCollisionRadius: Double

    let maxDebris: Int
    let debrisPerCollision: Int

    init(sim: SimSettings, scenario: Scenario) {
        self.sim = sim
        self.scenario = scenario
        self.effectiveCollisionRadius = sim.collisionRadius + ((sim.satelliteScale - 1.0) * 0.25)
        self.maxDebris = Int(sim.maxDebris)
        self.debrisPerCollision = Int(sim.debrisPerCollision)
    }
}
