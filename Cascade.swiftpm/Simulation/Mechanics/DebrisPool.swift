//
//  DebrisPool.swift
//  Cascade
//
//  Created by Pedro Wiezel on 15/02/26.
//

import Foundation
import RealityKit
import simd
import Accelerate

class DebrisPool {

    var posX: [Float]
    var posY: [Float]
    var posZ: [Float]

    var velX: [Float]
    var velY: [Float]
    var velZ: [Float]

    var rotAxisX: [Float]
    var rotAxisY: [Float]
    var rotAxisZ: [Float]
    var spinRate:  [Float]
    var rotAngle:  [Float]

    private(set) var activeCount: Int = 0
    let capacity: Int

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
        scratchA.initialize(repeating: 0, count: capacity)
        scratchB = .allocate(capacity: capacity)
        scratchB.initialize(repeating: 0, count: capacity)
        scratchC = .allocate(capacity: capacity)
        scratchC.initialize(repeating: 0, count: capacity)
    }

    deinit {
        scratchA.deinitialize(count: capacity)
        scratchA.deallocate()
        scratchB.deinitialize(count: capacity)
        scratchB.deallocate()
        scratchC.deinitialize(count: capacity)
        scratchC.deallocate()
    }

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
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1)
        )

        if length_squared(axis) == 0 {
            axis = [0, 1, 0]
        }

        let finalAxis = normalize(axis)

        rotAxisX[i] = finalAxis.x
        rotAxisY[i] = finalAxis.y
        rotAxisZ[i] = finalAxis.z

        spinRate[i] = Float.random(in: 1.0...6.0)
        rotAngle[i] = Float.random(in: 0...6.28)

        activeCount += 1
    }

    func kill(at index: Int) {
        guard index < activeCount else { return }
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

    func updatePhysics(dt: Float, earthMass: Float, killRadiusSq: Float, maxRadiusSq: Float) {
        guard activeCount > 0 else { return }
        let count = activeCount
        let n = vDSP_Length(count)

        withSixBuffers(&posX, &posY, &posZ, &velX, &velY, &velZ) { pX, pY, pZ, vX, vY, vZ in
            let xBase = pX.baseAddress!
            let yBase = pY.baseAddress!
            let zBase = pZ.baseAddress!
            let vxBase = vX.baseAddress!
            let vyBase = vY.baseAddress!
            let vzBase = vZ.baseAddress!

            vDSP_vsq(xBase, 1, scratchA, 1, n)
            vDSP_vsq(yBase, 1, scratchC, 1, n)
            vDSP_vadd(scratchA, 1, scratchC, 1, scratchA, 1, n)
            vDSP_vsq(zBase, 1, scratchC, 1, n)
            vDSP_vadd(scratchA, 1, scratchC, 1, scratchA, 1, n)

            var n32 = Int32(count)
            vvrsqrtf(scratchB, scratchA, &n32)

            vDSP_vmul(scratchB, 1, scratchB, 1, scratchC, 1, n)
            vDSP_vmul(scratchC, 1, scratchB, 1, scratchC, 1, n)
            var coeff = -earthMass * dt
            vDSP_vsmul(scratchC, 1, &coeff, scratchC, 1, n)

            for i in 0..<count {
                if scratchA[i] < killRadiusSq || scratchA[i] > maxRadiusSq {
                    scratchC[i] = 0
                }
            }

            vDSP_vma(xBase, 1, scratchC, 1, vxBase, 1, vxBase, 1, n)
            vDSP_vma(yBase, 1, scratchC, 1, vyBase, 1, vyBase, 1, n)
            vDSP_vma(zBase, 1, scratchC, 1, vzBase, 1, vzBase, 1, n)

            var dt_val = dt
            vDSP_vsma(vxBase, 1, &dt_val, xBase, 1, xBase, 1, n)
            vDSP_vsma(vyBase, 1, &dt_val, yBase, 1, yBase, 1, n)
            vDSP_vsma(vzBase, 1, &dt_val, zBase, 1, zBase, 1, n)
        }

        spinRate.withUnsafeBufferPointer { pSpin in
            rotAngle.withUnsafeMutableBufferPointer { pAngle in
                var dt_val = dt
                vDSP_vsma(pSpin.baseAddress!, 1, &dt_val, pAngle.baseAddress!, 1, pAngle.baseAddress!, 1, n)
            }
        }

        var i = 0
        while i < activeCount {
            let d = posX[i] * posX[i] + posY[i] * posY[i] + posZ[i] * posZ[i]
            if d < killRadiusSq || d > maxRadiusSq { kill(at: i) } else { i += 1 }
        }
    }

    @inline(__always)
    func position(at i: Int) -> SIMD3<Float> { SIMD3<Float>(posX[i], posY[i], posZ[i]) }

    @inline(__always)
    func velocity(at i: Int) -> SIMD3<Float> { SIMD3<Float>(velX[i], velY[i], velZ[i]) }

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
}

@inline(__always)
func withSixBuffers<T>(
    _ a: inout [T], _ b: inout [T], _ c: inout [T],
    _ d: inout [T], _ e: inout [T], _ f: inout [T],
    block: (UnsafeMutableBufferPointer<T>,
            UnsafeMutableBufferPointer<T>,
            UnsafeMutableBufferPointer<T>,
            UnsafeMutableBufferPointer<T>,
            UnsafeMutableBufferPointer<T>,
            UnsafeMutableBufferPointer<T>) -> Void
) {
    a.withUnsafeMutableBufferPointer { pA in
        b.withUnsafeMutableBufferPointer { pB in
            c.withUnsafeMutableBufferPointer { pC in
                d.withUnsafeMutableBufferPointer { pD in
                    e.withUnsafeMutableBufferPointer { pE in
                        f.withUnsafeMutableBufferPointer { pF in
                            block(pA, pB, pC, pD, pE, pF)
                        }
                    }
                }
            }
        }
    }
}
