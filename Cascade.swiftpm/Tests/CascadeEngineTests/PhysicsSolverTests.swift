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
                             dt: Float = 1.0 / 300.0,
                             indices: [Int]? = nil,
                             camera: SIMD3<Float> = SIMD3(0, 0, 900)) async -> SimulationFrame {
        await solver.step(
            dt: dt,
            earthMass: 150_000,
            satellitePositions: satellites,
            satelliteVelocities: Array(repeating: .zero, count: satellites.count),
            satelliteIndices: indices ?? Array(satellites.indices),
            cameraPosition: camera
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

    @Test("A retained frame stays unchanged when the solver reuses its buffer slot")
    func retainedFramesAreImmutable() async {
        let solver = Self.makeSolver()
        await solver.spawnExplosion(at: SIMD3(300, 0, 0), velocity: SIMD3(0, 0, 20))

        let original = await Self.step(solver, satellites: [])
        let originalCount = original.vertexBuffer.activeVertexCount
        let originalVertices = Array(original.vertexBuffer.vertices.prefix(originalCount))

        await solver.spawnExplosion(at: SIMD3(-300, 0, 0), velocity: SIMD3(0, 0, -20))
        for _ in 0..<3 {
            _ = await Self.step(solver, satellites: [])
        }

        #expect(original.vertexBuffer.activeVertexCount == originalCount)
        #expect(Array(original.vertexBuffer.vertices.prefix(originalCount)) == originalVertices)
    }

    @Test("Changing debris scale refreshes the cached fragment geometry")
    func debrisScaleUpdatesVertices() async {
        var sim = Self.settings().sim
        sim.debrisRotation = false
        let settings = EngineSettings(sim: sim, scenario: .defaults)
        let solver = PhysicsSolver(settings: settings, earthRadius: Self.earthRadius)
        let position = SIMD3<Float>(300, 0, 0)
        await solver.spawnExplosion(at: position, velocity: .zero)

        let before = await Self.step(solver, satellites: [], dt: 0)
        #expect(before.vertexBuffer.vertices[0] == position + DebrisMesh.corners[0])

        var scaled = settings.sim
        scaled.debrisScale = 2
        await solver.updateSettings(EngineSettings(sim: scaled, scenario: settings.scenario))
        let after = await Self.step(solver, satellites: [], dt: 0)
        #expect(after.vertexBuffer.vertices[0] == position + DebrisMesh.corners[0] * 2)
    }

    @Test("An empty universe returns an empty drawable frame")
    func emptyUniverse() async {
        let frame = await Self.step(Self.makeSolver(), satellites: [], dt: 0)

        #expect(frame.debrisCount == 0)
        #expect(frame.vertexBuffer.activeVertexCount == 0)
        #expect(frame.killedSatelliteIndices.isEmpty)
    }

    @Test("Collision deaths use the original satellite identifiers")
    func preservesSparseSatelliteIdentifiers() async {
        let position = SIMD3<Float>(300, 0, 0)
        let frame = await Self.step(
            Self.makeSolver(), satellites: [position, -position, position], dt: 0,
            indices: [17, 42, 93]
        )

        #expect(Set(frame.killedSatelliteIndices) == [17, 93])
        #expect(frame.killedSatelliteIndices.count == 2)
    }

    @Test("Satellite contact uses a strict spherical radius")
    func satelliteContactBoundaries() async {
        let origin = SIMD3<Float>(300, 0, 0)
        let offsets: [(SIMD3<Float>, Bool)] = [
            (SIMD3(0, 1.5, 0), true),
            (SIMD3(0, 2, 0), false),
            (SIMD3(0, 2.5, 0), false),
            (SIMD3(0, 1.5, 1.5), false)
        ]

        for (offset, collides) in offsets {
            let frame = await Self.step(Self.makeSolver(), satellites: [origin, origin + offset], dt: 0)
            #expect(frame.killedSatelliteIndices.count == (collides ? 2 : 0), "Offset: \(offset)")
            #expect((frame.debrisCount > 0) == collides)
        }
    }

    @Test("Debris contact uses the smaller fragment radius")
    func debrisContactBoundaries() async {
        let origin = SIMD3<Float>(300, 0, 0)
        for separation in [Float(0.5), 1, 1.5] {
            let solver = Self.makeSolver()
            await solver.spawnExplosion(at: origin, velocity: .zero)
            let frame = await Self.step(solver, satellites: [origin + SIMD3(0, separation, 0)], dt: 0)

            #expect(frame.killedSatelliteIndices == (separation < 1 ? [0] : []),
                    "Separation: \(separation)")
        }
    }

    @Test("Contacts across neighboring grid cells are detected")
    func contactsAcrossGridCells() async {
        let frame = await Self.step(
            Self.makeSolver(),
            satellites: [SIMD3(300, -0.25, -0.25), SIMD3(300, 0.25, 0.25)], dt: 0
        )

        #expect(Set(frame.killedSatelliteIndices) == [0, 1])
    }

    @Test("Batched collision results match an independent pairwise check")
    func collisionsMatchPairwiseReference() async {
        var positions: [SIMD3<Float>] = []
        for center in Self.ring(count: 150) {
            positions.append(contentsOf: [center, center + SIMD3(0, 1, 0), center + SIMD3(0, 6, 0)])
        }
        let identifiers = positions.indices.map { ($0 * 37) % 500 }
        var expectedDeaths: Set<Int> = []
        for first in positions.indices {
            for second in (first + 1)..<positions.count {
                if distance(positions[first], positions[second]) < 2 {
                    expectedDeaths.formUnion([identifiers[first], identifiers[second]])
                }
            }
        }

        let frame = await Self.step(Self.makeSolver(), satellites: positions, dt: 0, indices: identifiers)

        #expect(expectedDeaths.count == 300)
        #expect(Set(frame.killedSatelliteIndices) == expectedDeaths)
        #expect(frame.killedSatelliteIndices.count == expectedDeaths.count)
    }

    @Test("Shared debris contacts create one explosion per destroyed object")
    func sharedContactsExplodeEachObjectOnce() async {
        var sim = Self.settings().sim
        sim.debrisPerCollision = 5
        let solver = PhysicsSolver(settings: EngineSettings(sim: sim, scenario: .defaults),
                                   earthRadius: Self.earthRadius)
        let origin = SIMD3<Float>(300, 0, 0)
        for _ in 0..<100 {
            await solver.spawnExplosion(at: origin, velocity: .zero)
        }

        let frame = await Self.step(solver, satellites: [origin, origin], dt: 0)

        #expect(Set(frame.killedSatelliteIndices) == [0, 1])
        #expect(frame.killedSatelliteIndices.count == 2)
        #expect(frame.debrisCount == 2_510, "500 fragments and 2 satellites each create 5 fragments")
    }

    @Test("Live capacity changes trim existing debris and permit spawning after an increase")
    func liveDebrisCapacityChanges() async {
        var settings = Self.settings(maxDebris: 3_100)
        let solver = PhysicsSolver(settings: settings, earthRadius: Self.earthRadius)
        for _ in 0..<450 {
            await solver.spawnExplosion(at: SIMD3(300, 0, 0), velocity: .zero)
        }
        let full = await Self.step(solver, satellites: [], dt: 0)
        #expect(full.debrisCount == 3_100)

        settings = Self.settings(maxDebris: 3_000)
        await solver.updateSettings(settings)
        let trimmed = await Self.step(solver, satellites: [], dt: 0)
        #expect(trimmed.debrisCount == 3_000)
        #expect(trimmed.vertexBuffer.activeVertexCount == 3_000 * DebrisMesh.verticesPerFragment)

        await solver.spawnExplosion(at: SIMD3(300, 0, 0), velocity: .zero)
        let capped = await Self.step(solver, satellites: [], dt: 0)
        #expect(capped.debrisCount == 3_000)

        await solver.updateSettings(Self.settings(maxDebris: 3_100))
        await solver.spawnExplosion(at: SIMD3(300, 0, 0), velocity: .zero)
        let expanded = await Self.step(solver, satellites: [], dt: 0)
        #expect(expanded.debrisCount == 3_007)
    }

    @Test("Live elimination-radius changes remove fragments outside the new boundary")
    func liveEliminationRadiusChanges() async {
        var sim = Self.settings().sim
        let solver = PhysicsSolver(settings: EngineSettings(sim: sim, scenario: .defaults),
                                   earthRadius: Self.earthRadius)
        await solver.spawnExplosion(at: SIMD3(500, 0, 0), velocity: .zero)
        let before = await Self.step(solver, satellites: [], dt: 0)
        #expect(before.debrisCount == 7)

        sim.eliminationRadius = 380
        await solver.updateSettings(EngineSettings(sim: sim, scenario: .defaults))
        let after = await Self.step(solver, satellites: [], dt: 0)
        #expect(after.debrisCount == 0)
        #expect(after.vertexBuffer.activeVertexCount == 0)
    }

    @Test("Vertex workers preserve each fragment's position across chunk boundaries")
    func vertexAssemblyAcrossChunks() async {
        var sim = Self.settings().sim
        sim.debrisRotation = false
        let solver = PhysicsSolver(settings: EngineSettings(sim: sim, scenario: .defaults),
                                   earthRadius: Self.earthRadius)
        let positions = Self.ring(count: 80)
        for position in positions {
            await solver.spawnExplosion(at: position, velocity: .zero)
        }

        let frame = await Self.step(solver, satellites: [], dt: 0)

        #expect(frame.debrisCount == 560)
        #expect(frame.vertexBuffer.activeVertexCount == 560 * DebrisMesh.verticesPerFragment)
        for vertex in 0..<frame.vertexBuffer.activeVertexCount {
            let fragment = vertex / DebrisMesh.verticesPerFragment
            let corner = vertex % DebrisMesh.verticesPerFragment
            #expect(frame.vertexBuffer.vertices[vertex] == positions[fragment / 7] + DebrisMesh.corners[corner])
        }
    }

    @Test("Rotation preserves fragment geometry and distant fragments use unrotated geometry")
    func rotationAndDistanceLOD() async {
        let solver = Self.makeSolver()
        let origin = SIMD3<Float>(300, 0, 0)
        await solver.spawnExplosion(at: origin, velocity: .zero)
        let near = await Self.step(solver, satellites: [], dt: 0, camera: origin)

        for first in DebrisMesh.corners.indices {
            for second in (first + 1)..<DebrisMesh.corners.count {
                let expected = distance(DebrisMesh.corners[first], DebrisMesh.corners[second])
                let actual = distance(near.vertexBuffer.vertices[first], near.vertexBuffer.vertices[second])
                #expect(abs(actual - expected) < 0.0001)
            }
        }

        let far = await Self.step(solver, satellites: [], dt: 0, camera: SIMD3(0, 0, 2_000))
        for corner in DebrisMesh.corners.indices {
            #expect(far.vertexBuffer.vertices[corner] == origin + DebrisMesh.corners[corner])
        }

        let advanced = await Self.step(solver, satellites: [], dt: 0.1, camera: origin)
        // Edge vectors remove translation, so only fragment rotation can change them.
        let rotated = DebrisMesh.corners.indices.dropFirst().contains { corner in
            let before = near.vertexBuffer.vertices[corner] - near.vertexBuffer.vertices[0]
            let after = advanced.vertexBuffer.vertices[corner] - advanced.vertexBuffer.vertices[0]
            return distance(before, after) > 0.001
        }
        #expect(rotated, "A nearby fragment must visibly rotate as its spin advances")
    }

    @Test("Radial velocities produce finite fragments on every principal axis",
          arguments: [SIMD3<Float>(300, 0, 0), SIMD3<Float>(0, 300, 0), SIMD3<Float>(0, 0, 300)])
    func radialExplosionDirectionsStayFinite(position: SIMD3<Float>) async {
        let solver = PhysicsSolver(settings: EngineSettings(sim: .defaults, scenario: .defaults),
                                   earthRadius: Self.earthRadius)
        await solver.spawnExplosion(at: position, velocity: normalize(position) * 20)
        let frame = await Self.step(solver, satellites: [], dt: 0)

        #expect(frame.debrisCount == 7)
        let vertices = frame.vertexBuffer.vertices.prefix(frame.vertexBuffer.activeVertexCount)
        #expect(vertices.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
    }
}
