//
//  EngineSettings.swift
//  Cascade
//

struct EngineSettings: Sendable {

    let sim: SimSettings

    let scenario: Scenario

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
