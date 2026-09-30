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

        pool.kill(at: 1)

        #expect(pool.activeCount == 3)
        #expect(pool.position(at: 0) == SIMD3(0, 0, 0))
        #expect(pool.position(at: 1) == SIMD3(3, 6, 9))
        #expect(pool.position(at: 2) == SIMD3(2, 4, 6))
        pool.withCollisionBuffers { buffers in
            #expect(buffers.velX[1] == 30)
        }
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
        pool.spawn(at: SIMD3(300, 0, 0), velocity: .zero)
        pool.spawn(at: SIMD3(10, 0, 0), velocity: .zero)
        pool.spawn(at: SIMD3(5_000, 0, 0), velocity: .zero)

        pool.updatePhysics(dt: 0, earthMass: 150_000,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 1)
        #expect(pool.position(at: 0).x == 300)
    }

    @Test("Non-finite fragments are culled without losing valid neighbors",
          arguments: [Float.nan, .infinity, -.infinity])
    func cullsNonFiniteFragments(bad: Float) {
        let pool = DebrisPool(capacity: 4)
        pool.spawn(at: SIMD3(bad, 0, 0), velocity: .zero)
        pool.spawn(at: SIMD3(300, 0, 0), velocity: .zero)
        pool.spawn(at: SIMD3(0, 300, 0), velocity: SIMD3(0, bad, 0))
        pool.spawn(at: SIMD3(0, 0, 300), velocity: .zero)

        pool.updatePhysics(dt: 1.0 / 300.0, earthMass: 0,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 2)
        let positions = Set((0..<pool.activeCount).map { pool.position(at: $0) })
        #expect(positions == [SIMD3(300, 0, 0), SIMD3(0, 0, 300)])
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

        let finalRadius = length(pool.position(at: 0))
        #expect(abs(finalRadius - radius) < radius * 0.02)
    }

    @Test("Without gravity, fragments move at their original velocity on every axis")
    func zeroGravityIsLinearMotion() {
        let pool = DebrisPool(capacity: 3)
        let positions: [SIMD3<Float>] = [SIMD3(300, 20, -10), SIMD3(-30, 300, 40), SIMD3(10, -20, 300)]
        let velocities: [SIMD3<Float>] = [SIMD3(4, -8, 12), SIMD3(-6, 2, -4), SIMD3(0, 16, -8)]
        for index in positions.indices {
            pool.spawn(at: positions[index], velocity: velocities[index])
        }

        pool.updatePhysics(dt: 0.5, earthMass: 0,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == positions.count)
        pool.withCollisionBuffers { buffers in
            for index in positions.indices {
                #expect(pool.position(at: index) == positions[index] + velocities[index] * 0.5)
                #expect(SIMD3(buffers.velX[index], buffers.velY[index], buffers.velZ[index]) == velocities[index])
            }
        }
    }

    @Test("A zero-duration step leaves valid positions, velocities and orientations unchanged")
    func zeroDurationPreservesState() {
        let pool = DebrisPool(capacity: 1)
        let position = SIMD3<Float>(300, 20, -10)
        let velocity = SIMD3<Float>(-3, 5, 7)
        pool.spawn(at: position, velocity: velocity)
        var originalAngle: Float = 0
        var originalAxis = SIMD3<Float>.zero
        pool.withVertexBuffers { buffers in
            originalAngle = buffers.rotAngle[0]
            originalAxis = SIMD3(buffers.rotAxisX[0], buffers.rotAxisY[0], buffers.rotAxisZ[0])
        }

        pool.updatePhysics(dt: 0, earthMass: 150_000,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 1)
        #expect(pool.position(at: 0) == position)
        pool.withCollisionBuffers { buffers in
            #expect(SIMD3(buffers.velX[0], buffers.velY[0], buffers.velZ[0]) == velocity)
        }
        pool.withVertexBuffers { buffers in
            #expect(buffers.rotAngle[0] == originalAngle.truncatingRemainder(dividingBy: 2 * .pi))
            #expect(SIMD3(buffers.rotAxisX[0], buffers.rotAxisY[0], buffers.rotAxisZ[0]) == originalAxis)
        }
    }

    @Test("Crossing either lifetime boundary during integration removes the fragment immediately")
    func cullsAfterCrossingBoundary() {
        let pool = DebrisPool(capacity: 3)
        pool.spawn(at: SIMD3(250, 0, 0), velocity: SIMD3(-20, 0, 0))
        pool.spawn(at: SIMD3(590, 0, 0), velocity: SIMD3(20, 0, 0))
        pool.spawn(at: SIMD3(300, 0, 0), velocity: SIMD3(20, 0, 0))

        pool.updatePhysics(dt: 1, earthMass: 0,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 1)
        #expect(pool.position(at: 0) == SIMD3(320, 0, 0))
    }

    @Test("Fragments exactly on a lifetime boundary survive")
    func lifetimeBoundariesAreInclusive() {
        let pool = DebrisPool(capacity: 4)
        for radius in [Float(241.5), 242, 600, 600.5] {
            pool.spawn(at: SIMD3(radius, 0, 0), velocity: .zero)
        }

        pool.updatePhysics(dt: 0, earthMass: 150_000,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 2)
        #expect(Set((0..<pool.activeCount).map { pool.position(at: $0).x }) == [242, 600])
    }

    @Test("Compaction rechecks replacements when several removed fragments occupy the tail")
    func cullingRechecksSwappedFragments() {
        let pool = DebrisPool(capacity: 6)
        for radius in [Float(10), 300, 700, 400, 20, 800] {
            pool.spawn(at: SIMD3(radius, 0, 0), velocity: .zero)
        }

        pool.updatePhysics(dt: 0, earthMass: 150_000,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 2)
        #expect(Set((0..<pool.activeCount).map { pool.position(at: $0).x }) == [300, 400])
    }

    @Test("Swap removal preserves the surviving fragment's orientation")
    func swapRemovePreservesOrientation() {
        let pool = DebrisPool(capacity: 3)
        for index in 0..<3 {
            pool.spawn(at: SIMD3(300, Float(index), 0), velocity: .zero)
        }
        var originalAxis = SIMD3<Float>.zero
        var originalAngle: Float = 0
        pool.withVertexBuffers { buffers in
            originalAxis = SIMD3(buffers.rotAxisX[2], buffers.rotAxisY[2], buffers.rotAxisZ[2])
            originalAngle = buffers.rotAngle[2]
        }

        pool.kill(at: 0)

        #expect(pool.activeCount == 2)
        #expect(pool.position(at: 0) == SIMD3(300, 2, 0))
        pool.withVertexBuffers { buffers in
            #expect(SIMD3(buffers.rotAxisX[0], buffers.rotAxisY[0], buffers.rotAxisZ[0]) == originalAxis)
            #expect(buffers.rotAngle[0] == originalAngle)
        }
    }

    @Test("Trimming cannot revive fragments, and freed slots accept complete replacement state")
    func trimAndReuse() {
        let pool = DebrisPool(capacity: 4)
        for index in 0..<4 {
            pool.spawn(at: SIMD3(300, Float(index), 0), velocity: .zero)
        }

        pool.trimTo(2)
        pool.trimTo(4)
        #expect(pool.activeCount == 2)
        let newPosition = SIMD3<Float>(-300, 10, 20)
        let newVelocity = SIMD3<Float>(1, 2, 3)
        pool.spawn(at: newPosition, velocity: newVelocity)

        #expect(pool.activeCount == 3)
        #expect(pool.position(at: 0) == SIMD3(300, 0, 0))
        #expect(pool.position(at: 1) == SIMD3(300, 1, 0))
        #expect(pool.position(at: 2) == newPosition)
        pool.withCollisionBuffers { buffers in
            #expect(SIMD3(buffers.velX[2], buffers.velY[2], buffers.velZ[2]) == newVelocity)
        }
    }

    @Test("Resetting a populated pool permits a fresh fragment in its first slot")
    func resetAndReuse() {
        let pool = DebrisPool(capacity: 2)
        pool.spawn(at: SIMD3(300, 0, 0), velocity: SIMD3(20, 30, 40))
        pool.spawn(at: SIMD3(-300, 0, 0), velocity: SIMD3(-20, -30, -40))
        pool.reset()
        pool.updatePhysics(dt: 1, earthMass: 150_000,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)
        #expect(pool.activeCount == 0)

        pool.spawn(at: SIMD3(0, 300, 0), velocity: SIMD3(0, 0, 25))

        #expect(pool.activeCount == 1)
        #expect(pool.position(at: 0) == SIMD3(0, 300, 0))
        pool.withCollisionBuffers { buffers in
            #expect(SIMD3(buffers.velX[0], buffers.velY[0], buffers.velZ[0]) == SIMD3(0, 0, 25))
        }
    }

    @Test("Spin axes stay normalized and long advances wrap angles into one revolution")
    func spinStateStaysBounded() {
        let pool = DebrisPool(capacity: 32)
        for _ in 0..<32 {
            pool.spawn(at: SIMD3(300, 0, 0), velocity: .zero)
        }

        pool.updatePhysics(dt: 1_000, earthMass: 0,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)

        #expect(pool.activeCount == 32)
        pool.withVertexBuffers { buffers in
            for index in 0..<pool.activeCount {
                let axis = SIMD3(buffers.rotAxisX[index], buffers.rotAxisY[index], buffers.rotAxisZ[index])
                #expect(abs(length_squared(axis) - 1) < 0.00001)
                #expect(buffers.rotAngle[index].isFinite)
                #expect(buffers.rotAngle[index] >= 0 && buffers.rotAngle[index] < 2 * .pi)
            }
        }
    }

    @Test("Fragment rotation advances over time at a steady angular speed")
    func spinAdvancesAtSteadyRate() {
        let pool = DebrisPool(capacity: 8)
        for _ in 0..<8 {
            pool.spawn(at: SIMD3(300, 0, 0), velocity: .zero)
        }

        func angles() -> [Float] {
            var values: [Float] = []
            pool.withVertexBuffers { buffers in
                values = Array(buffers.rotAngle.prefix(pool.activeCount))
            }
            return values
        }

        func angularAdvance(from start: Float, to end: Float) -> Float {
            let difference = end - start
            return difference >= 0 ? difference : difference + 2 * .pi
        }

        let initial = angles()
        pool.updatePhysics(dt: 0.1, earthMass: 0,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)
        let afterShortStep = angles()
        pool.updatePhysics(dt: 0.2, earthMass: 0,
                           killRadiusSq: 242 * 242, maxRadiusSq: 600 * 600)
        let afterLongStep = angles()

        #expect(pool.activeCount == initial.count)
        for index in 0..<pool.activeCount {
            let firstAdvance = angularAdvance(from: initial[index], to: afterShortStep[index])
            let secondAdvance = angularAdvance(from: afterShortStep[index], to: afterLongStep[index])
            #expect(firstAdvance > 0)
            #expect(abs(secondAdvance - firstAdvance * 2) < 0.00001)
        }
    }
}
