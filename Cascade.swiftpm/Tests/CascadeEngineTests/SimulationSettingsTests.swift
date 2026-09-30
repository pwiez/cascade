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
        let simulation = Simulation(controller: SimulationControllerSpy())

        simulation.settings = SimSettings(
            debrisPerCollision: 10,
            explosionForce: 2,
            collisionRadius: 2,
            maxDebris: 7_000,
            eliminationRadius: 800,
            spreadTangential: 1.2,
            spreadVertical: 1.3,
            spreadRadial: 1.4,
            timeScale: 4.2,
            gravityMultiplier: 1.5,
            satelliteColor: .blue,
            debrisColor: .yellow,
            backgroundColor: .black,
            satelliteScale: 2,
            debrisScale: 3,
            debrisRotation: false,
            useOmniLight: true,
            showEarth: false,
            showSatellites: false,
            showDebris: false
        )
        simulation.draft = Scenario(
            satelliteCount: 475, orbitAltitude: 310, orbitVariance: 25,
            useRandomInclination: false
        )

        simulation.resetSettingsToDefaults()

        #expect(simulation.settings == .defaults)
        #expect(simulation.draft == .defaults)
    }

    @Test("Scenario edits stay pending until the simulation is restarted")
    @MainActor
    func scenarioEditsRequireRestart() {
        let simulation = Simulation(controller: SimulationControllerSpy())
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
