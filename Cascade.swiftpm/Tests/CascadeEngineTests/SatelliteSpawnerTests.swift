//
//  SatelliteSpawnerTests.swift
//  CascadeEngineTests
//

import RealityKit
import Testing
import UIKit
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

    @Test("Empty and boundary-sized constellations have the requested number of independent entities",
          arguments: [0, 1, Capacity.maxSatellites], [false, true])
    func constellationSize(count: Int, randomInclination: Bool) {
        let satellites = Self.makeSatellites(settings: .defaults, randomInclination: randomInclination, count: count)

        #expect(satellites.count == count)
        #expect(Set(satellites.map(ObjectIdentifier.init)).count == count)
        #expect(satellites.allSatisfy { $0.parent == nil && $0.isEnabled })
    }

    @Test("Ring satellites are spaced evenly around the equator")
    func ringSpacingIsUniform() {
        let satellites = Self.makeSatellites(settings: .defaults, randomInclination: false)
        let expectedDot = cos(2 * Float.pi / Float(satellites.count))

        for index in satellites.indices {
            let current = normalize(satellites[index].position)
            let next = normalize(satellites[(index + 1) % satellites.count].position)
            #expect(abs(dot(current, next) - expectedDot) < 0.00001)
        }
        let center = satellites.reduce(SIMD3<Float>.zero) { $0 + $1.position } / Float(satellites.count)
        #expect(length(center) < 0.001)
    }

    @Test("Shell constellations occupy both hemispheres of every axis")
    func shellCoversThreeDimensions() {
        let satellites = Self.makeSatellites(settings: .defaults, randomInclination: true, count: 100)
        let directions = satellites.map { normalize($0.position) }

        for axis in 0..<3 {
            #expect(directions.contains { $0[axis] > 0.5 })
            #expect(directions.contains { $0[axis] < -0.5 })
        }
    }

    @Test("Orbit variance preserves radius bounds, tangency, and circular speed", arguments: [false, true])
    func orbitalGeometryRespectsSettings(randomInclination: Bool) throws {
        var sim = SimSettings.defaults
        sim.gravityMultiplier = 2
        var scenario = Scenario.defaults
        scenario.orbitAltitude = 300
        scenario.orbitVariance = 40
        scenario.useRandomInclination = randomInclination
        let satellites = SatelliteSpawner.makeSatellites(
            count: 100, settings: EngineSettings(sim: sim, scenario: scenario), earthMass: 150_000,
            mesh: .generateBox(size: 2.25), material: UnlitMaterial(color: .green)
        )

        for satellite in satellites {
            let radius = length(satellite.position)
            let velocity = try #require(satellite.components[OrbitalData.self]).velocity
            #expect(radius >= 259.999 && radius <= 340.001)
            #expect(abs(dot(normalize(satellite.position), normalize(velocity))) < 0.001)
            #expect(abs(length_squared(velocity) - 300_000 / radius) < 0.01)
        }
    }

    @Test("Visible satellites share the supplied geometry and color at the configured scale")
    func appearanceIsApplied() throws {
        var sim = SimSettings.defaults
        sim.satelliteScale = SimSettings.scaleRange.upperBound
        let mesh = MeshResource.generateBox(size: 2.25)
        let material = UnlitMaterial(color: .magenta)
        let satellites = SatelliteSpawner.makeSatellites(
            count: 3, settings: EngineSettings(sim: sim, scenario: .defaults), earthMass: 150_000,
            mesh: mesh, material: material
        )

        for satellite in satellites {
            let model = try #require(satellite.model)
            let renderedMaterial = try #require(model.materials.first as? UnlitMaterial)
            #expect(model.mesh === mesh)
            try expectColor(renderedMaterial.color.tint, red: 1, green: 0, blue: 1)
            #expect(satellite.scale == SIMD3(repeating: Float(sim.satelliteScale)))
        }
    }

    @Test("Zero gravity produces stationary satellites with finite positions", arguments: [false, true])
    func zeroGravityDoesNotCreateInvalidVelocity(randomInclination: Bool) throws {
        var sim = SimSettings.defaults
        sim.gravityMultiplier = 0
        let satellites = Self.makeSatellites(settings: sim, randomInclination: randomInclination)

        for satellite in satellites {
            let orbit = try #require(satellite.components[OrbitalData.self])
            #expect(orbit.velocity == .zero)
            #expect(satellite.position.x.isFinite && satellite.position.y.isFinite && satellite.position.z.isFinite)
        }
    }

    private static func makeSatellites(settings: SimSettings, randomInclination: Bool = true,
                                       count: Int = 12) -> [ModelEntity] {
        var scenario = Scenario.defaults
        scenario.orbitVariance = 0
        scenario.useRandomInclination = randomInclination
        return SatelliteSpawner.makeSatellites(
            count: count, settings: EngineSettings(sim: settings, scenario: scenario), earthMass: 150_000,
            mesh: .generateBox(size: 2.25), material: UnlitMaterial(color: .green)
        )
    }
}
