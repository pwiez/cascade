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
    
    
    var activeCount: Int = 0
    let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
        
        self.posX = Array(repeating: 0, count: capacity)
        self.posY = Array(repeating: 0, count: capacity)
        self.posZ = Array(repeating: 0, count: capacity)
        
        self.velX = Array(repeating: 0, count: capacity)
        self.velY = Array(repeating: 0, count: capacity)
        self.velZ = Array(repeating: 0, count: capacity)
    }
    
    func reset() {
        activeCount = 0
    }
    
    func spawn(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
        guard activeCount < capacity else { return }
        let index = activeCount
        
        posX[index] = position.x
        posY[index] = position.y
        posZ[index] = position.z
        
        velX[index] = velocity.x
        velY[index] = velocity.y
        velZ[index] = velocity.z
        
        activeCount += 1
    }
    
    func kill(at index: Int) {
        guard index < activeCount else { return }
        let lastIndex = activeCount - 1
        
        if index != lastIndex {
            posX[index] = posX[lastIndex]
            posY[index] = posY[lastIndex]
            posZ[index] = posZ[lastIndex]
            
            velX[index] = velX[lastIndex]
            velY[index] = velY[lastIndex]
            velZ[index] = velZ[lastIndex]
        }
        activeCount -= 1
    }
    
    func updatePhysics(dt: Float, earthMass: Float, killRadiusSq: Float, maxRadiusSq: Float) {
        guard activeCount > 0 else { return }
        
        withSixBuffers(&posX, &posY, &posZ, &velX, &velY, &velZ) { ptrX, ptrY, ptrZ, vPtrX, vPtrY, vPtrZ in
            
            if activeCount < 1000 {
                            for i in 0..<activeCount {
                                performGravity(i: i, ptrX: ptrX, ptrY: ptrY, ptrZ: ptrZ, vPtrX: vPtrX, vPtrY: vPtrY, vPtrZ: vPtrZ, earthMass: earthMass, dt: dt, killRadiusSq: killRadiusSq, maxRadiusSq: maxRadiusSq)
                            }
                        } else {
                            DispatchQueue.concurrentPerform(iterations: activeCount) { i in
                                performGravity(i: i, ptrX: ptrX, ptrY: ptrY, ptrZ: ptrZ, vPtrX: vPtrX, vPtrY: vPtrY, vPtrZ: vPtrZ, earthMass: earthMass, dt: dt, killRadiusSq: killRadiusSq, maxRadiusSq: maxRadiusSq)
                            }
                        }
        }
        
        var delta = dt
        vDSP_vma(velX, 1, &delta, 0, posX, 1, &posX, 1, vDSP_Length(activeCount))
        vDSP_vma(velY, 1, &delta, 0, posY, 1, &posY, 1, vDSP_Length(activeCount))
        vDSP_vma(velZ, 1, &delta, 0, posZ, 1, &posZ, 1, vDSP_Length(activeCount))
        
        var i = 0
        while i < activeCount {
            let px = posX[i]
            let py = posY[i]
            let pz = posZ[i]
            let distSq = (px*px) + (py*py) + (pz*pz)
            
            if distSq < killRadiusSq || distSq > maxRadiusSq {
                kill(at: i)
            } else {
                i += 1
            }
        }
    }
    
    @inline(__always)
    func performGravity(i: Int,
                                    ptrX: UnsafeMutableBufferPointer<Float>,
                                    ptrY: UnsafeMutableBufferPointer<Float>,
                                    ptrZ: UnsafeMutableBufferPointer<Float>,
                                    vPtrX: UnsafeMutableBufferPointer<Float>,
                                    vPtrY: UnsafeMutableBufferPointer<Float>,
                                    vPtrZ: UnsafeMutableBufferPointer<Float>,
                                    earthMass: Float, dt: Float,
                                    killRadiusSq: Float, maxRadiusSq: Float) {
            
            let px = ptrX[i]
            let py = ptrY[i]
            let pz = ptrZ[i]
            
            let distSq = (px*px) + (py*py) + (pz*pz)
            
            if distSq < killRadiusSq || distSq > maxRadiusSq { return }
            
            let invDist = 1.0 / sqrt(distSq)
            let invDist3 = invDist * invDist * invDist
            let factor = -earthMass * invDist3 * dt
            
            vPtrX[i] += px * factor
            vPtrY[i] += py * factor
            vPtrZ[i] += pz * factor
        }
    
    @inline(__always)
    func position(at i: Int) -> SIMD3<Float> {
        return SIMD3<Float>(posX[i], posY[i], posZ[i])
    }
    
    @inline(__always)
    func velocity(at i: Int) -> SIMD3<Float> {
        return SIMD3<Float>(velX[i], velY[i], velZ[i])
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
