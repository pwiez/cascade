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
    }

    func reset() {
        activeCount = 0
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

        let axis = normalize(SIMD3<Float>(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1)
        ))
        rotAxisX[i] = axis.x
        rotAxisY[i] = axis.y
        rotAxisZ[i] = axis.z
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

        withSixBuffers(&posX, &posY, &posZ, &velX, &velY, &velZ) { pX, pY, pZ, vX, vY, vZ in
            if count < 1000 {
                for i in 0..<count {
                    DebrisPool.applyGravity(
                        i: i,
                        ptrX: pX, ptrY: pY, ptrZ: pZ,
                        vPtrX: vX, vPtrY: vY, vPtrZ: vZ,
                        earthMass: earthMass, dt: dt,
                        killRadiusSq: killRadiusSq, maxRadiusSq: maxRadiusSq
                    )
                }
            } else {
                struct Ptrs: @unchecked Sendable {
                    let px, py, pz, vx, vy, vz: UnsafeMutableBufferPointer<Float>
                }
                let p = Ptrs(px: pX, py: pY, pz: pZ, vx: vX, vy: vY, vz: vZ)
                DispatchQueue.concurrentPerform(iterations: count) { i in
                    DebrisPool.applyGravity(
                        i: i,
                        ptrX: p.px, ptrY: p.py, ptrZ: p.pz,
                        vPtrX: p.vx, vPtrY: p.vy, vPtrZ: p.vz,
                        earthMass: earthMass, dt: dt,
                        killRadiusSq: killRadiusSq, maxRadiusSq: maxRadiusSq
                    )
                }
            }
        }

        var delta = dt
        vDSP_vma(velX, 1, &delta, 0, posX, 1, &posX, 1, vDSP_Length(count))
        vDSP_vma(velY, 1, &delta, 0, posY, 1, &posY, 1, vDSP_Length(count))
        vDSP_vma(velZ, 1, &delta, 0, posZ, 1, &posZ, 1, vDSP_Length(count))
        vDSP_vma(spinRate, 1, &delta, 0, rotAngle, 1, &rotAngle, 1, vDSP_Length(count))

        var i = 0
        while i < activeCount {
            let d = posX[i] * posX[i] + posY[i] * posY[i] + posZ[i] * posZ[i]
            if d < killRadiusSq || d > maxRadiusSq { kill(at: i) } else { i += 1 }
        }
    }

    @inline(__always)
    static func applyGravity(i: Int,
                             ptrX: UnsafeMutableBufferPointer<Float>,
                             ptrY: UnsafeMutableBufferPointer<Float>,
                             ptrZ: UnsafeMutableBufferPointer<Float>,
                             vPtrX: UnsafeMutableBufferPointer<Float>,
                             vPtrY: UnsafeMutableBufferPointer<Float>,
                             vPtrZ: UnsafeMutableBufferPointer<Float>,
                             earthMass: Float, dt: Float,
                             killRadiusSq: Float, maxRadiusSq: Float) {
        let px = ptrX[i], py = ptrY[i], pz = ptrZ[i]
        let distSq = px*px + py*py + pz*pz
        guard distSq >= killRadiusSq && distSq <= maxRadiusSq else { return }

        let invDist = simd_rsqrt(distSq)
        let factor = -earthMass * invDist * invDist * invDist * dt
        vPtrX[i] += px * factor
        vPtrY[i] += py * factor
        vPtrZ[i] += pz * factor
    }

    @inline(__always)
    func position(at i: Int) -> SIMD3<Float> { SIMD3<Float>(posX[i], posY[i], posZ[i]) }

    @inline(__always)
    func velocity(at i: Int) -> SIMD3<Float> { SIMD3<Float>(velX[i], velY[i], velZ[i]) }
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
