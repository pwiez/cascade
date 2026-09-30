//
//  SatelliteSpawnerTests.swift
//  CascadeEngineTests
//

import RealityKit
import Testing
import simd
@testable import CascadeEngine

@Suite("Satellite creation")
@MainActor
struct SatelliteSpawnerTests {
    @Test("Rebuilding a hidden constellation preserves its orbits without showing models")
    func hiddenSatellitesKeepPhysics() throws {
        var settings = SimSettings.defaults
        settings.showSatellites = false
        settings.satelliteScale = 2
        let satellites = Self.makeSatellites(settings: settings)

        #expect(satellites.count == 12)
        for satellite in satellites {
            #expect(satellite.isEnabled)
            #expect(satellite.model == nil)
            #expect(satellite.scale == SIMD3(repeating: 2))
            let orbit = try #require(satellite.components[OrbitalData.self])
            #expect(abs(length(satellite.position) - 290) < 0.001)
            #expect(abs(dot(normalize(satellite.position), normalize(orbit.velocity))) < 0.001)
            #expect(abs(length_squared(orbit.velocity) - 150_000 / 290) < 0.001)
        }
    }

    @Test("Visible ring satellites retain their models and equatorial orbits")
    func visibleRing() {
        let satellites = Self.makeSatellites(settings: .defaults, randomInclination: false)
        #expect(satellites.count == 12)
        for satellite in satellites {
            #expect(satellite.model != nil)
            #expect(satellite.position.y == 0)
            #expect(satellite.components[OrbitalData.self]?.velocity.y == 0)
        }
    }

    private static func makeSatellites(settings: SimSettings, randomInclination: Bool = true) -> [ModelEntity] {
        var scenario = Scenario.defaults
        scenario.orbitVariance = 0
        scenario.useRandomInclination = randomInclination
        return SatelliteSpawner.makeSatellites(
            count: 12, settings: EngineSettings(sim: settings, scenario: scenario), earthMass: 150_000,
            mesh: .generateBox(size: 2.25), material: UnlitMaterial(color: .green)
        )
    }
}
