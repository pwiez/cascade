//
//  SimulationSettingsTests.swift
//  CascadeEngineTests
//

import Testing
@testable import CascadeEngine

@Suite("Settings")
struct SimulationSettingsTests {

    @Test("Resetting restores every tunable, not just the ones someone listed")
    @MainActor
    func resetRestoresEverySetting() {
        let simulation = Simulation()

        simulation.settings.debrisPerCollision = 10
        simulation.settings.maxDebris = 7_000
        simulation.settings.debrisRotation = false
        simulation.settings.showSatellites = false
        simulation.settings.timeScale = 4.2
        simulation.draft.satelliteCount = 475

        simulation.resetSettingsToDefaults()

        #expect(simulation.settings == .defaults)
        #expect(simulation.draft == .defaults)
    }

    @Test("Scenario edits stay pending until the simulation is restarted")
    @MainActor
    func scenarioEditsRequireRestart() {
        let simulation = Simulation()
        #expect(!simulation.hasPendingChanges)

        simulation.draft.orbitAltitude = 310
        #expect(simulation.hasPendingChanges)
        #expect(simulation.active.orbitAltitude == Scenario.defaults.orbitAltitude,
                "the running universe must not change until it is rebuilt")

        simulation.resetSimulation()
        #expect(!simulation.hasPendingChanges)
        #expect(simulation.active.orbitAltitude == 310)
    }

    @Test("Slider ranges stay inside the engine's fixed capacities")
    func sliderRangesFitCapacity() {
        let maxOverspawn = Int(SimSettings.debrisPerCollisionRange.upperBound)
        #expect(Int(SimSettings.maxDebrisRange.upperBound) + maxOverspawn <= Capacity.maxDebris)
        #expect(Int(Scenario.satelliteCountRange.upperBound) <= Capacity.maxSatellites)
        #expect(Capacity.gridObjects >= Capacity.maxDebris + Capacity.maxSatellites)
    }

    @Test("The collision hitbox grows with the satellites' visual scale")
    func hitboxTracksVisualScale() {
        var sim = SimSettings.defaults
        sim.collisionRadius = 1.0
        sim.satelliteScale = 1.0
        let unscaled = EngineSettings(sim: sim, scenario: .defaults)

        sim.satelliteScale = 5.0
        let scaled = EngineSettings(sim: sim, scenario: .defaults)

        #expect(scaled.effectiveCollisionRadius > unscaled.effectiveCollisionRadius)
        #expect(unscaled.effectiveCollisionRadius == 1.0)
    }

    @Test("Defaults land inside their own slider ranges")
    func defaultsAreInRange() {
        let d = SimSettings.defaults
        #expect(SimSettings.debrisPerCollisionRange.contains(d.debrisPerCollision))
        #expect(SimSettings.explosionForceRange.contains(d.explosionForce))
        #expect(SimSettings.collisionRadiusRange.contains(d.collisionRadius))
        #expect(SimSettings.maxDebrisRange.contains(d.maxDebris))
        #expect(SimSettings.eliminationRadiusRange.contains(d.eliminationRadius))
        #expect(SimSettings.timeScaleRange.contains(d.timeScale))
        #expect(SimSettings.scaleRange.contains(d.satelliteScale))
        #expect(SimSettings.scaleRange.contains(d.debrisScale))

        let s = Scenario.defaults
        #expect(Scenario.satelliteCountRange.contains(s.satelliteCount))
        #expect(Scenario.orbitAltitudeRange.contains(s.orbitAltitude))
        #expect(Scenario.orbitVarianceRange.contains(s.orbitVariance))
    }
}
