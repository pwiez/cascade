//
//  PhysicsSolver.swift
//  Cascade
//
//  Created by Pedro Wiezel on 10/02/26.
//

import Foundation
import RealityKit
import simd

enum BodyType { case leo, debris }

struct OrbitalData: Component {
    var velocity: SIMD3<Float>
    var radius: Float
    var type: BodyType
}

struct CollisionEvent: Sendable {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
}

struct SimulationFrame: Sendable {
    let count: Int
    
    let posX: [Float]
    let posY: [Float]
    let posZ: [Float]
    
    let rotAngle: [Float]
    let rotAxisX: [Float]
    let rotAxisY: [Float]
    let rotAxisZ: [Float]
    
    let killedSatelliteIndices: [Int]
    let explosions: [CollisionEvent]
    
    static let empty = SimulationFrame(
        count: 0,
        posX: [], posY: [], posZ: [],
        rotAngle: [], rotAxisX: [], rotAxisY: [], rotAxisZ: [],
        killedSatelliteIndices: [],
        explosions: []
    )
}

actor PhysicsSolver {
    
    final class ThreadResult: @unchecked Sendable {
        var explosions: [CollisionEvent] = []
        var deaths: [Int] = []
        var debrisKills: [Int] = []
    }
    
    private var threadBuckets: [ThreadResult] = []
    
    private var debrisPool: DebrisPool
    private var grid: SpatialGrid
    
    private var killRadiusSq: Float
    private let maxRadiusSq: Float
    private var settings: SimSettings
    
    init(settings: SimSettings, earthRadius: Float) {
        self.settings = settings
        self.killRadiusSq = pow(earthRadius + 2.0, 2)
        self.maxRadiusSq = 300 * 300
        
        self.debrisPool = DebrisPool(capacity: 5500)
        
        let minGridWidth: Float = 350.0
        let requiredCellSize = minGridWidth / 128.0
        let safeCellSize = max(Float(settings.collisionRadius * 2.1), requiredCellSize)
        self.grid = SpatialGrid(maxObjects: 6000, cellSize: safeCellSize)
        
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        self.threadBuckets = (0..<coreCount).map { _ in
            let bucket = ThreadResult()
            bucket.explosions.reserveCapacity(100)
            bucket.deaths.reserveCapacity(50)
            bucket.debrisKills.reserveCapacity(100)
            return bucket
        }
    }
    
    func step(dt: Float,
              earthMass: Float,
              satellitePositions: [SIMD3<Float>],
              satelliteVelocities: [SIMD3<Float>],
              satelliteIndices: [Int]) -> SimulationFrame {
        
        debrisPool.updatePhysics(
            dt: dt,
            earthMass: earthMass,
            killRadiusSq: killRadiusSq,
            maxRadiusSq: maxRadiusSq
        )
        
        if debrisPool.activeCount > settings.maxDebris {
            let excess = debrisPool.activeCount - settings.maxDebris
            for _ in 0..<excess { debrisPool.kill(at: 0) }
        }
        
        var killedSats: [Int] = []
        var explosions: [CollisionEvent] = []
        
        let hasSatellites = !satellitePositions.isEmpty
        let hasDebris = debrisPool.activeCount > 0
        let possibleSatCollision = satellitePositions.count > 1
        
        if (hasSatellites && hasDebris) || possibleSatCollision {
            let results = performCollisionCheck(
                satPos: satellitePositions,
                satVel: satelliteVelocities,
                satIdx: satelliteIndices
            )
            killedSats = results.deaths
            explosions = results.explosions
        }
        
        let count = debrisPool.activeCount
        return SimulationFrame(
            count: count,
            posX: Array(debrisPool.posX[0..<count]),
            posY: Array(debrisPool.posY[0..<count]),
            posZ: Array(debrisPool.posZ[0..<count]),
            rotAngle: Array(debrisPool.rotAngle[0..<count]),
            rotAxisX: Array(debrisPool.rotAxisX[0..<count]),
            rotAxisY: Array(debrisPool.rotAxisY[0..<count]),
            rotAxisZ: Array(debrisPool.rotAxisZ[0..<count]),
            killedSatelliteIndices: killedSats,
            explosions: explosions
        )
    }
    
    func updateSettings(_ newSettings: SimSettings) {
        let oldRadius = Float(self.settings.collisionRadius)
        let newRadius = Float(newSettings.collisionRadius)
        
        if abs(oldRadius - newRadius) > 0.5 {
            let minGridWidth: Float = 350.0
            let requiredCellSize = minGridWidth / 128.0
            let safeCellSize = max(newRadius * 2.1, requiredCellSize)
            self.grid = SpatialGrid(maxObjects: 6_000, cellSize: safeCellSize)
        }
        
        self.settings = newSettings
    }
    
    func reset() {
        debrisPool.reset()
        grid.clear()
    }
    
    func spawnExplosion(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
        guard debrisPool.activeCount < settings.maxDebris else { return }
        
        let debrisCount = min(Int(settings.debrisPerCollision), 25)
        let explosionForce = Float(settings.explosionForce) * 2.0
        
        let vNorm = length(velocity)
        let velocityDirection = vNorm > 0.001 ? velocity / vNorm : SIMD3<Float>(0, 1, 0)
        let pNorm = length(position)
        let radialDirection = pNorm > 0.001 ? position / pNorm : SIMD3<Float>(0, 1, 0)
        let normalDirection = normalize(cross(velocityDirection, radialDirection))
        
        let scaleTangential = Float(settings.spreadTangential)
        let scaleVertical = Float(settings.spreadVertical) * 3.0
        let scaleRadial = Float(settings.spreadRadial)
        
        for _ in 0..<debrisCount {
            guard debrisPool.activeCount < settings.maxDebris else { break }
            
            let rT = Float.random(in: -0.2...0.2) * scaleTangential
            let rV = Float.random(in: -1...1) * scaleVertical
            let rR = Float.random(in: -7...7) * scaleRadial
            
            let impulse = (velocityDirection * rT) +
            (normalDirection * rV) +
            (radialDirection * rR)
            
            let speedVariance = Float.random(in: 0.8...1.4)
            var finalVelocity = velocity + (impulse * explosionForce * speedVariance)
            
            if length(finalVelocity) < 10.0 {
                finalVelocity = normalize(finalVelocity) * 12.0
            }
            
            debrisPool.spawn(at: position + (impulse * 0.5), velocity: finalVelocity)
        }
    }
    
    private func performCollisionCheck(satPos: [SIMD3<Float>],
                                       satVel: [SIMD3<Float>],
                                       satIdx: [Int]) -> (deaths: [Int], explosions: [CollisionEvent]) {
        let satCount = satPos.count
        
        grid.clear()
        for i in 0..<satCount { grid.add(objectIndex: i, position: satPos[i]) }
        for i in 0..<debrisPool.activeCount { grid.add(objectIndex: satCount + i, position: debrisPool.position(at: i)) }
        
        let radius = Float(settings.collisionRadius)
        let radiusSq = radius * radius
        
        let localGrid = self.grid
        let dPosX = debrisPool.posX
        let dPosY = debrisPool.posY
        let dPosZ = debrisPool.posZ
        let dVelX = debrisPool.velX
        let dVelY = debrisPool.velY
        let dVelZ = debrisPool.velZ
        let dActive = debrisPool.activeCount
        
        let totalObjects = satCount + debrisPool.activeCount
        let objectsPerCore = 250
        let desiredCores = max(1, totalObjects / objectsPerCore)
        let coreCount = min(desiredCores, threadBuckets.count)
        let buckets = threadBuckets
        
        for i in 0..<coreCount {
            buckets[i].explosions.removeAll(keepingCapacity: true)
            buckets[i].deaths.removeAll(keepingCapacity: true)
            buckets[i].debrisKills.removeAll(keepingCapacity: true)
        }
        
        DispatchQueue.concurrentPerform(iterations: coreCount) { coreIndex in
            let bucket = buckets[coreIndex]
            
            for i in stride(from: coreIndex, to: satCount, by: coreCount) {
                let posA = satPos[i]
                let cellID = localGrid.getCellIndex(for: posA)
                guard cellID != -1 else { continue }
                
                for offset in localGrid.neighborOffsets {
                    var neighborIdx = localGrid.firstObject(inCell: cellID + offset)
                    
                    while neighborIdx != -1 {
                        defer { neighborIdx = localGrid.nextObject(after: neighborIdx) }
                        guard neighborIdx > i else { continue }
                        
                        let posB: SIMD3<Float>
                        let velB: SIMD3<Float>
                        let isDebris: Bool
                        
                        if neighborIdx < satCount {
                            posB = satPos[neighborIdx]
                            velB = satVel[neighborIdx]
                            isDebris = false
                        } else {
                            let dIdx = neighborIdx - satCount
                            guard dIdx < dActive else { continue }
                            posB = SIMD3(dPosX[dIdx], dPosY[dIdx], dPosZ[dIdx])
                            velB = SIMD3(dVelX[dIdx], dVelY[dIdx], dVelZ[dIdx])
                            isDebris = true
                        }
                        
                        let effectiveRadius = isDebris ? radius : (radius * 2)
                        guard abs(posA.x - posB.x) <= effectiveRadius &&
                                abs(posA.y - posB.y) <= effectiveRadius &&
                                abs(posA.z - posB.z) <= effectiveRadius else { continue }
                        let effectiveRSq = isDebris ? radiusSq : (radius * 2) * (radius * 2)
                        guard length_squared(posA - posB) < effectiveRSq else { continue }
                        
                        bucket.deaths.append(satIdx[i])
                        bucket.explosions.append(CollisionEvent(position: posA, velocity: satVel[i]))
                        
                        if isDebris {
                            bucket.debrisKills.append(neighborIdx - satCount)
                            bucket.explosions.append(CollisionEvent(position: posB, velocity: velB))
                        } else {
                            bucket.deaths.append(satIdx[neighborIdx])
                            bucket.explosions.append(CollisionEvent(position: posB, velocity: velB))
                        }
                    }
                }
            }
        }
        
        let finalDeaths = buckets.flatMap { $0.deaths }
        let finalDebrisKills = buckets.flatMap { $0.debrisKills }
        let finalExplosions = buckets.flatMap { $0.explosions }
        
        for debrisIndex in Set(finalDebrisKills).sorted(by: >) {
            debrisPool.kill(at: debrisIndex)
        }
        for boom in finalExplosions {
            spawnExplosion(at: boom.position, velocity: boom.velocity)
        }
        
        return (finalDeaths, finalExplosions)
    }
}
