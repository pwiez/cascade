//
//  PhysicsSolverTests.swift
//  CascadeEngineTests
//

import Foundation
import Testing
import simd
@testable import CascadeEngine

@Suite("PhysicsSolver")
struct PhysicsSolverTests {

    private static let earthRadius: Float = 240

    private static func settings(maxDebris: Double = 7_500) -> EngineSettings {
        var sim = SimSettings.defaults
        sim.spreadTangential = 0
        sim.spreadVertical = 0
        sim.spreadRadial = 0
        sim.explosionForce = 0.5
        sim.maxDebris = maxDebris
        return EngineSettings(sim: sim, scenario: .defaults)
    }

    private static func makeSolver(maxDebris: Double = 7_500) -> PhysicsSolver {
        PhysicsSolver(settings: settings(maxDebris: maxDebris), earthRadius: earthRadius)
    }

    private static func ring(count: Int, radius: Float = 300) -> [SIMD3<Float>] {
        (0..<count).map { i in
            let angle = (Float(i) / Float(count)) * 2 * .pi
            return SIMD3(cos(angle) * radius, 0, sin(angle) * radius)
        }
    }

    private static func step(_ solver: PhysicsSolver,
                             satellites: [SIMD3<Float>],
                             dt: Float = 1.0 / 300.0) async -> SimulationFrame {
        await solver.step(
            dt: dt,
            earthMass: 150_000,
            satellitePositions: satellites,
            satelliteVelocities: Array(repeating: .zero, count: satellites.count),
            satelliteIndices: Array(satellites.indices),
            cameraPosition: SIMD3(0, 0, 900)
        )
    }

    @Test("A quiet frame after a busy one produces no debris")
    func staleBucketsAreNotReplayed() async throws {
        try #require(ProcessInfo.processInfo.activeProcessorCount > 1,
                     "needs more than one worker for stale buckets to exist at all")

        let solver = Self.makeSolver()

        let satellites = Self.ring(count: 300)
        for position in stride(from: 0, to: satellites.count, by: 6).map({ satellites[$0] }) {
            await solver.spawnExplosion(at: position, velocity: .zero)
        }

        let busy = await Self.step(solver, satellites: satellites)
        #expect(busy.debrisCount > 0, "the busy frame should have produced debris")

        await solver.reset()

        let quiet = await Self.step(solver, satellites: [SIMD3(300, 0, 0), SIMD3(-300, 0, 0)])

        #expect(quiet.debrisCount == 0, "debris appeared with no collision to create it")
        #expect(quiet.killedSatelliteIndices.isEmpty, "a satellite died with nothing to hit it")

        let stillQuiet = await Self.step(solver, satellites: [SIMD3(300, 0, 0), SIMD3(-300, 0, 0)])
        #expect(stillQuiet.debrisCount == 0)
        #expect(stillQuiet.killedSatelliteIndices.isEmpty)
    }

    @Test("A satellite hit by many fragments is only reported dead once")
    func satelliteDeathsAreNotDuplicated() async {
        let solver = Self.makeSolver()
        let target = SIMD3<Float>(300, 0, 0)

        for _ in 0..<4 {
            await solver.spawnExplosion(at: target, velocity: .zero)
        }

        let frame = await Self.step(solver, satellites: [target, SIMD3(-300, 0, 0)])
        let deaths = frame.killedSatelliteIndices

        #expect(deaths.count == Set(deaths).count, "the same satellite was reported dead twice")
        #expect(deaths.contains(0), "the satellite inside the debris cloud should have died")
    }

    @Test("Two satellites in the same place destroy each other")
    func satellitesCollide() async {
        let solver = Self.makeSolver()
        let position = SIMD3<Float>(300, 0, 0)

        let frame = await Self.step(solver, satellites: [position, position])

        #expect(Set(frame.killedSatelliteIndices) == [0, 1])
        #expect(frame.debrisCount > 0, "the collision should have produced debris")
    }

    @Test("Distant satellites are left alone")
    func distantSatellitesDoNotCollide() async {
        let solver = Self.makeSolver()

        let frame = await Self.step(solver, satellites: [SIMD3(300, 0, 0), SIMD3(-300, 0, 0)])

        #expect(frame.killedSatelliteIndices.isEmpty)
        #expect(frame.debrisCount == 0)
    }

    @Test("Debris never exceeds the configured ceiling")
    func respectsMaxDebris() async {
        let ceiling = 3_000.0
        let solver = Self.makeSolver(maxDebris: ceiling)

        for i in 0..<800 {
            let angle = Float(i) * 0.31
            await solver.spawnExplosion(at: SIMD3(cos(angle) * 300, 0, sin(angle) * 300), velocity: .zero)
        }

        let frame = await Self.step(solver, satellites: [])
        #expect(frame.debrisCount <= Int(ceiling))
        #expect(frame.debrisCount <= Capacity.maxDebris)
    }

    @Test("A cancelling ejection impulse cannot produce a NaN position")
    func zeroVelocityFragmentsStayFinite() async {
        var sim = SimSettings.defaults
        sim.explosionForce = SimSettings.explosionForceRange.upperBound
        sim.spreadTangential = 0
        sim.spreadVertical = 0
        sim.spreadRadial = 0
        let solver = PhysicsSolver(
            settings: EngineSettings(sim: sim, scenario: .defaults),
            earthRadius: Self.earthRadius
        )

        for _ in 0..<200 {
            await solver.spawnExplosion(at: SIMD3(300, 0, 0), velocity: .zero)
        }

        for _ in 0..<10 {
            let frame = await Self.step(solver, satellites: [SIMD3(300, 0, 0)])
            let vertices = frame.vertexBuffer.vertices.prefix(frame.debrisCount * 4)
            #expect(vertices.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
        }
    }

    @Test("Reset clears every fragment")
    func resetClearsDebris() async {
        let solver = Self.makeSolver()
        await solver.spawnExplosion(at: SIMD3(300, 0, 0), velocity: .zero)

        var frame = await Self.step(solver, satellites: [])
        #expect(frame.debrisCount > 0)

        await solver.reset()
        frame = await Self.step(solver, satellites: [])
        #expect(frame.debrisCount == 0)
    }
}
