//
//  DebrisPool.swift
//  Cascade
//
//  Created by Pedro Wiezel on 15/02/26.
//

import Accelerate
import simd

/// Every debris fragment in the simulation, stored as a structure of arrays.
///
/// The layout is the point. One array per component — all the X positions
/// together, then all the Y positions — rather than an array of structs, because
/// the gravity integration touches every position and every velocity in
/// sequence. Contiguous single-component runs are what let `vDSP` process them
/// in SIMD batches, and what keeps the cache line full of data the next
/// iteration actually wants.
///
/// Capacity is fixed at construction and fragments are recycled by swapping the
/// last live one into the hole, so the pool never allocates while running.
final class DebrisPool {

    private(set) var posX: [Float]
    private(set) var posY: [Float]
    private(set) var posZ: [Float]

    private(set) var velX: [Float]
    private(set) var velY: [Float]
    private(set) var velZ: [Float]

    private(set) var rotAxisX: [Float]
    private(set) var rotAxisY: [Float]
    private(set) var rotAxisZ: [Float]
    private(set) var spinRate: [Float]
    private(set) var rotAngle: [Float]

    private(set) var activeCount = 0
    let capacity: Int

    /// Working space for the vDSP pipeline.
    ///
    /// Raw pointers rather than `[Float]`: the integration already holds
    /// exclusive mutable access to six of the arrays above, and reaching for a
    /// seventh Swift array inside that closure would trip exclusivity checking.
    /// These are owned outright and freed in `deinit`.
    private let scratchA: UnsafeMutablePointer<Float>
    private let scratchB: UnsafeMutablePointer<Float>
    private let scratchC: UnsafeMutablePointer<Float>

    init(capacity: Int) {
        self.capacity = capacity

        posX = Array(repeating: 0, count: capacity)
        posY = Array(repeating: 0, count: capacity)
        posZ = Array(repeating: 0, count: capacity)

        velX = Array(repeating: 0, count: capacity)
        velY = Array(repeating: 0, count: capacity)
        velZ = Array(repeating: 0, count: capacity)

        rotAxisX = Array(repeating: 0, count: capacity)
        rotAxisY = Array(repeating: 1, count: capacity)
        rotAxisZ = Array(repeating: 0, count: capacity)
        spinRate = Array(repeating: 0, count: capacity)
        rotAngle = Array(repeating: 0, count: capacity)

        scratchA = .allocate(capacity: capacity)
        scratchB = .allocate(capacity: capacity)
        scratchC = .allocate(capacity: capacity)
        scratchA.initialize(repeating: 0, count: capacity)
        scratchB.initialize(repeating: 0, count: capacity)
        scratchC.initialize(repeating: 0, count: capacity)
    }

    deinit {
        for scratch in [scratchA, scratchB, scratchC] {
            scratch.deinitialize(count: capacity)
            scratch.deallocate()
        }
    }

    // MARK: - Lifetime

    func reset() {
        activeCount = 0
    }

    func trimTo(_ count: Int) {
        activeCount = min(activeCount, count)
    }

    func spawn(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
        guard activeCount < capacity else { return }
        let i = activeCount

        posX[i] = position.x
        posY[i] = position.y
        posZ[i] = position.z

        velX[i] = velocity.x
        velY[i] = velocity.y
        velZ[i] = velocity.z

        var axis = SIMD3<Float>(
            .random(in: -1...1),
            .random(in: -1...1),
            .random(in: -1...1)
        )
        if length_squared(axis) < 1e-6 { axis = SIMD3(0, 1, 0) }
        let unitAxis = normalize(axis)

        rotAxisX[i] = unitAxis.x
        rotAxisY[i] = unitAxis.y
        rotAxisZ[i] = unitAxis.z

        spinRate[i] = .random(in: 1.0...6.0)
        rotAngle[i] = .random(in: 0...(2 * .pi))

        activeCount += 1
    }

    /// Recycles a fragment by moving the last live one into its slot.
    ///
    /// O(1), but it reorders the pool — callers iterating while killing must walk
    /// downwards so the element swapped in has already been visited.
    func kill(at index: Int) {
        guard index >= 0, index < activeCount else { return }
        let last = activeCount - 1

        if index != last {
            posX[index] = posX[last]
            posY[index] = posY[last]
            posZ[index] = posZ[last]

            velX[index] = velX[last]
            velY[index] = velY[last]
            velZ[index] = velZ[last]

            rotAxisX[index] = rotAxisX[last]
            rotAxisY[index] = rotAxisY[last]
            rotAxisZ[index] = rotAxisZ[last]
            spinRate[index] = spinRate[last]
            rotAngle[index] = rotAngle[last]
        }
        activeCount -= 1
    }

    // MARK: - Integration

    /// Advances every fragment one step and culls whatever left the simulated shell.
    ///
    /// Semi-implicit Euler: velocity is updated from the current position, then
    /// position from the *new* velocity. That ordering is what makes it
    /// symplectic — orbits stay closed instead of spiralling out the way explicit
    /// Euler would send them.
    func updatePhysics(dt: Float, earthMass: Float, killRadiusSq: Float, maxRadiusSq: Float) {
        guard activeCount > 0 else { return }
        let count = activeCount
        let n = vDSP_Length(count)

        withPositionAndVelocityBuffers { pX, pY, pZ, vX, vY, vZ in
            guard let x = pX.baseAddress, let y = pY.baseAddress, let z = pZ.baseAddress,
                  let vx = vX.baseAddress, let vy = vY.baseAddress, let vz = vZ.baseAddress else { return }

            // scratchA = |p|²
            squaredDistance(x: x, y: y, z: z, into: scratchA, count: n)

            // scratchC = -GM·dt / |p|³, the gravitational coefficient per fragment.
            var elementCount = Int32(count)
            vvrsqrtf(scratchB, scratchA, &elementCount)          // 1/|p|
            vDSP_vmul(scratchB, 1, scratchB, 1, scratchC, 1, n)  // 1/|p|²
            vDSP_vmul(scratchC, 1, scratchB, 1, scratchC, 1, n)  // 1/|p|³
            var coefficient = -earthMass * dt
            vDSP_vsmul(scratchC, 1, &coefficient, scratchC, 1, n)

            // Fragments already outside the shell get zero acceleration; they are
            // culled below and pulling them further would only make that worse.
            for i in 0..<count where scratchA[i] < killRadiusSq || scratchA[i] > maxRadiusSq {
                scratchC[i] = 0
            }

            vDSP_vma(x, 1, scratchC, 1, vx, 1, vx, 1, n)
            vDSP_vma(y, 1, scratchC, 1, vy, 1, vy, 1, n)
            vDSP_vma(z, 1, scratchC, 1, vz, 1, vz, 1, n)

            var step = dt
            vDSP_vsma(vx, 1, &step, x, 1, x, 1, n)
            vDSP_vsma(vy, 1, &step, y, 1, y, 1, n)
            vDSP_vsma(vz, 1, &step, z, 1, z, 1, n)

            // Recompute distances at the new positions for the cull pass.
            squaredDistance(x: x, y: y, z: z, into: scratchA, count: n)
        }

        advanceSpin(dt: dt, count: count, n: n)
        cullOutOfRange(killRadiusSq: killRadiusSq, maxRadiusSq: maxRadiusSq)
    }

    private func squaredDistance(x: UnsafeMutablePointer<Float>,
                                 y: UnsafeMutablePointer<Float>,
                                 z: UnsafeMutablePointer<Float>,
                                 into out: UnsafeMutablePointer<Float>,
                                 count n: vDSP_Length) {
        vDSP_vsq(x, 1, out, 1, n)
        vDSP_vsq(y, 1, scratchC, 1, n)
        vDSP_vadd(out, 1, scratchC, 1, out, 1, n)
        vDSP_vsq(z, 1, scratchC, 1, n)
        vDSP_vadd(out, 1, scratchC, 1, out, 1, n)
    }

    private func advanceSpin(dt: Float, count: Int, n: vDSP_Length) {
        rotAngle.withUnsafeMutableBufferPointer { angles in
            spinRate.withUnsafeBufferPointer { rates in
                guard let angle = angles.baseAddress, let rate = rates.baseAddress else { return }
                var step = dt
                vDSP_vsma(rate, 1, &step, angle, 1, angle, 1, n)
            }
            // Wrap so the angle can't drift into the range where Float loses the
            // precision to represent a smooth rotation.
            let twoPi = 2 * Float.pi
            for i in 0..<count where abs(angles[i]) >= twoPi {
                angles[i] = angles[i].truncatingRemainder(dividingBy: twoPi)
            }
        }
    }

    /// Removes fragments that hit Earth or drifted past the elimination radius.
    private func cullOutOfRange(killRadiusSq: Float, maxRadiusSq: Float) {
        var i = 0
        while i < activeCount {
            let distanceSq = scratchA[i]
            if distanceSq < killRadiusSq || distanceSq > maxRadiusSq {
                kill(at: i)
                // `kill` swapped the last fragment into slot i, so its distance
                // has to follow it or the next iteration tests a stale value.
                scratchA[i] = scratchA[activeCount]
            } else {
                i += 1
            }
        }
    }

    // MARK: - Access

    @inline(__always)
    func position(at i: Int) -> SIMD3<Float> {
        SIMD3(posX[i], posY[i], posZ[i])
    }

    /// Read-only pointers for the collision pass.
    struct CollisionBuffers: @unchecked Sendable {
        let posX, posY, posZ: UnsafeBufferPointer<Float>
        let velX, velY, velZ: UnsafeBufferPointer<Float>
    }

    func withCollisionBuffers<R>(_ body: (CollisionBuffers) -> R) -> R {
        posX.withUnsafeBufferPointer { pX in
        posY.withUnsafeBufferPointer { pY in
        posZ.withUnsafeBufferPointer { pZ in
        velX.withUnsafeBufferPointer { vX in
        velY.withUnsafeBufferPointer { vY in
        velZ.withUnsafeBufferPointer { vZ in
            body(CollisionBuffers(posX: pX, posY: pY, posZ: pZ, velX: vX, velY: vY, velZ: vZ))
        }}}}}}
    }

    /// Read-only pointers for building the render mesh.
    struct VertexBuffers: @unchecked Sendable {
        let posX, posY, posZ: UnsafeBufferPointer<Float>
        let rotAxisX, rotAxisY, rotAxisZ: UnsafeBufferPointer<Float>
        let rotAngle: UnsafeBufferPointer<Float>
    }

    func withVertexBuffers<R>(_ body: (VertexBuffers) -> R) -> R {
        posX.withUnsafeBufferPointer { pX in
        posY.withUnsafeBufferPointer { pY in
        posZ.withUnsafeBufferPointer { pZ in
        rotAxisX.withUnsafeBufferPointer { rX in
        rotAxisY.withUnsafeBufferPointer { rY in
        rotAxisZ.withUnsafeBufferPointer { rZ in
        rotAngle.withUnsafeBufferPointer { rA in
            body(VertexBuffers(posX: pX, posY: pY, posZ: pZ,
                               rotAxisX: rX, rotAxisY: rY, rotAxisZ: rZ,
                               rotAngle: rA))
        }}}}}}}
    }

    private func withPositionAndVelocityBuffers(
        _ body: (UnsafeMutableBufferPointer<Float>, UnsafeMutableBufferPointer<Float>,
                 UnsafeMutableBufferPointer<Float>, UnsafeMutableBufferPointer<Float>,
                 UnsafeMutableBufferPointer<Float>, UnsafeMutableBufferPointer<Float>) -> Void
    ) {
        posX.withUnsafeMutableBufferPointer { pX in
        posY.withUnsafeMutableBufferPointer { pY in
        posZ.withUnsafeMutableBufferPointer { pZ in
        velX.withUnsafeMutableBufferPointer { vX in
        velY.withUnsafeMutableBufferPointer { vY in
        velZ.withUnsafeMutableBufferPointer { vZ in
            body(pX, pY, pZ, vX, vY, vZ)
        }}}}}}
    }
}
