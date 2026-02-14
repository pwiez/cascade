//
//  DebrisPool.swift
//  Kessler
//
//  Created by Pedro Wiezel on 13/02/26.
//

import Foundation
import RealityKit
import simd

class DebrisPool {
    var positions: ContiguousArray<SIMD3<Float>>
    var velocities: ContiguousArray<SIMD3<Float>>
    var orientations: ContiguousArray<simd_quatf>
    var entities: ContiguousArray<ModelEntity>
    
    var activeCount: Int = 0
    let capacity: Int
    
    init(capacity: Int, prototypeMeshes: [MeshResource], materials: [Material]) {
        self.capacity = capacity
        self.positions = ContiguousArray(repeating: .zero, count: capacity)
        self.velocities = ContiguousArray(repeating: .zero, count: capacity)
        self.orientations = ContiguousArray(repeating: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), count: capacity)
        self.entities = ContiguousArray()
        self.entities.reserveCapacity(capacity)
        
        for _ in 0..<capacity {
            let mesh = prototypeMeshes.randomElement() ?? prototypeMeshes[0]
            let material = materials.randomElement() ?? materials[0]
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.isEnabled = false
            self.entities.append(entity)
        }
    }
    
    func reset() {
        activeCount = 0
        for i in 0..<entities.count { entities[i].isEnabled = false }
    }
    
    func spawn(at position: SIMD3<Float>, velocity: SIMD3<Float>, orientation: simd_quatf, scale: Float) {
        guard activeCount < capacity else { return }
        let index = activeCount
        
        positions[index] = position
        velocities[index] = velocity
        orientations[index] = orientation
        
        let entity = entities[index]
        entity.position = position
        entity.orientation = orientation
        entity.scale = SIMD3<Float>(repeating: scale)
        entity.isEnabled = true
        
        activeCount += 1
    }
    
    func kill(at index: Int) {
        guard index < activeCount else { return }
        let lastIndex = activeCount - 1
        
        entities[index].isEnabled = false
        
        if index != lastIndex {
            positions[index] = positions[lastIndex]
            velocities[index] = velocities[lastIndex]
            orientations[index] = orientations[lastIndex]
            entities.swapAt(index, lastIndex)
        }
        
        activeCount -= 1
    }
    
    func updatePhysics(dt: Float, earthMass: Float, killRadiusSq: Float, maxRadiusSq: Float, scale: Float, rotDelta: simd_quatf) {
        
        positions.withUnsafeMutableBufferPointer { posPtr in
            velocities.withUnsafeMutableBufferPointer { velPtr in
                DispatchQueue.concurrentPerform(iterations: activeCount) { i in
                    let pos = posPtr[i]
                    let distSq = length_squared(pos)
                    
                    if distSq < killRadiusSq || distSq > maxRadiusSq { return }
                    
                    let invDist = simd_rsqrt(distSq)
                    let gravityAccel = -(earthMass * pos) * (invDist * invDist * invDist)
                    
                    velPtr[i] += gravityAccel * dt
                    posPtr[i] += velPtr[i] * dt
                }
            }
        }
        
        var killList: [Int] = []
        killList.reserveCapacity(100)
        
        for i in 0..<activeCount {
            let distSq = length_squared(positions[i])
            
            if distSq < killRadiusSq || distSq > maxRadiusSq {
                killList.append(i)
                continue
            }
            
            let entity = entities[i]
            entity.position = positions[i]
            
            orientations[i] *= rotDelta
            entity.orientation = orientations[i]
            
            if entity.scale.x != scale {
                entity.scale = SIMD3<Float>(repeating: scale)
            }
        }
        
        for index in killList.sorted(by: >) {
            self.kill(at: index)
        }
    }
}
