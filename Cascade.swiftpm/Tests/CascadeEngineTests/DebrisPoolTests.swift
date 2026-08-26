//
//  DebrisPoolTests.swift
//  CascadeEngineTests
//

import Testing
import simd
@testable import CascadeEngine

@Suite("DebrisPool")
struct DebrisPoolTests {

    @Test("Killing a fragment moves the last one into its slot intact")
    func swapRemovePreservesSurvivors() {
        let pool = DebrisPool(capacity: 8)
        for i in 0..<4 {
            pool.spawn(at: SIMD3(Float(i), Float(i) * 2, Float(i) * 3),
                       velocity: SIMD3(Float(i) * 10, 0, 0))
        }
        #expect(pool.activeCount == 4)

        // Remove index 1. Index 3 should take its place, complete and unmangled.
        pool.kill(at: 1)

        #expect(pool.activeCount == 3)
        #expect(pool.position(at: 0) == SIMD3(0, 0, 0))
        #expect(pool.position(at: 1) == SIMD3(3, 6, 9))
        #expect(pool.position(at: 2) == SIMD3(2, 4, 6))
        #expect(pool.velX[1] == 30)
    }

    @Test("Killing the last fragment needs no swap")
    func killingLastElement() {
        let pool = DebrisPool(capacity: 4)
        pool.spawn(at: SIMD3(1, 1, 1), velocity: .zero)
        pool.spawn(at: SIMD3(2, 2, 2), velocity: .zero)

        pool.kill(at: 1)

        #expect(pool.activeCount == 1)
        #expect(pool.position(at: 0) == SIMD3(1, 1, 1))
    }

    @Test("Out-of-range kills are ignored rather than corrupting the count")
    func killOutOfRange() {
        let pool = DebrisPool(capacity: 4)
        pool.spawn(at: .zero, velocity: .zero)

        pool.kill(at: 5)
        pool.kill(at: -1)

        #expect(pool.activeCount == 1)
    }

    @Test("Spawning past capacity drops the fragment instead of overflowing")
    func respectsCapacity() {
        let pool = DebrisPool(capacity: 2)
        for _ in 0..<10 {
            pool.spawn(at: .zero, velocity: .zero)
        }
        #expect(pool.activeCount == 2)
    }

    @Test("Fragments that fall to Earth or escape are culled")
    func cullsOutOfRange() {
        let pool = DebrisPool(capacity: 8)
        pool.spawn(at: SIMD3(300, 0, 0), velocity: .zero)   // in the shell
        pool.spawn(at: SIMD3(10, 0, 0), velocity: .zero)    // inside Earth
        pool.spawn(at: SIMD3(5_000, 0, 0), velocity: .zero) // escaped

        // dt of zero: the cull runs, but nothing moves, so the test is only
        // measuring the culling rule.
        pool.updatePhysics(dt: 0, earthMass: 150_000,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 1)
        #expect(pool.position(at: 0).x == 300)
    }

    @Test("A circular orbit stays circular over ten thousand steps")
    func symplecticIntegratorConservesOrbit() {
        let pool = DebrisPool(capacity: 2)
        let earthMass: Float = 150_000
        let radius: Float = 300
        let speed = (earthMass / radius).squareRoot()

        pool.spawn(at: SIMD3(radius, 0, 0), velocity: SIMD3(0, 0, speed))

        for _ in 0..<10_000 {
            pool.updatePhysics(dt: 1.0 / 300.0, earthMass: earthMass,
                               killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)
        }

        #expect(pool.activeCount == 1, "the fragment should not have deorbited or escaped")

        // Semi-implicit Euler wobbles a little but must not spiral: explicit
        // Euler would have gained energy and drifted outward by now.
        let finalRadius = length(pool.position(at: 0))
        #expect(abs(finalRadius - radius) < radius * 0.02)
    }
}
