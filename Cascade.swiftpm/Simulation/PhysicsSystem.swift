import Foundation
import simd

struct SimulationFrame: Sendable {
    let count: Int
    let posX: [Float]
    let posY: [Float]
    let posZ: [Float]
    
    let killedSatelliteIndices: [Int]
    let explosions: [CollisionEvent]
    
    static let empty = SimulationFrame(count: 0, posX: [], posY: [], posZ: [], killedSatelliteIndices: [], explosions: [])
}

actor PhysicsSystem {
    
    private var debrisPool: DebrisPool
    private var grid: SpatialGrid
    
    private let killRadiusSq: Float
    private let maxRadiusSq: Float
    private var settings: SimSettings
    
    init(settings: SimSettings, earthRadius: Float) {
        self.settings = settings
        self.killRadiusSq = pow(earthRadius + 2.0, 2)
        self.maxRadiusSq = 250.0 * 250.0
        
        self.debrisPool = DebrisPool(capacity: 5_500)
        self.grid = SpatialGrid(maxObjects: 6_000, cellSize: 6.0)
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
        
        let possibleSatCollisions = satellitePositions.count > 1
        
        if (hasSatellites && hasDebris) || possibleSatCollisions {
            let results = performCollisionCheck(
                satPos: satellitePositions,
                satVel: satelliteVelocities,
                satIdx: satelliteIndices
            )
            killedSats = results.deaths
            explosions = results.explosions
        }
        
        let count = debrisPool.activeCount
        let frame = SimulationFrame(
            count: count,
            posX: Array(debrisPool.posX[0..<count]),
            posY: Array(debrisPool.posY[0..<count]),
            posZ: Array(debrisPool.posZ[0..<count]),
            killedSatelliteIndices: killedSats,
            explosions: explosions
        )
        
        return frame
    }
    
    func updateSettings(_ newSettings: SimSettings) {
        self.settings = newSettings
    }
    
    func reset() {
        debrisPool.reset()
        grid.clear()
    }
    
    func spawnExplosion(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
            if debrisPool.activeCount >= settings.maxDebris { return }
            
            let debrisCount = min(Int(settings.debrisPerCollision), 25)
            
            let explosionImpulse = Float(settings.explosionForce) * 2.0
            
            let vNorm = length(velocity)
            let velocityDirection = vNorm > 0.001 ? velocity / vNorm : SIMD3<Float>(0, 1, 0)
            
            let pNorm = length(position)
            let radialDirection = pNorm > 0.001 ? position / pNorm : SIMD3<Float>(0, 1, 0)
            
            let normalDirection = normalize(cross(velocityDirection, radialDirection))
            
            let scaleTangential = Float(settings.spreadTangential)
            
            let scaleVertical = Float(settings.spreadVertical) * 3.0
            
            let scaleRadial = Float(settings.spreadRadial)
            
            for _ in 0...debrisCount {
                if debrisPool.activeCount >= settings.maxDebris { break }
                
                let rT = Float.random(in: -0.2...0.2) * scaleTangential
                let rV = Float.random(in: -1...1) * scaleVertical
                let rR = Float.random(in: -0.1...0.1) * scaleRadial
                
                let impulseVector = (velocityDirection * rT) +
                                    (normalDirection * rV) +
                                    (radialDirection * rR)
                
                let speedVariance = Float.random(in: 0.8...1.4)
                var finalVelocity = velocity + (impulseVector * explosionImpulse * speedVariance)
                
                if length(finalVelocity) < 10.0 {
                    finalVelocity = normalize(finalVelocity) * 12.0
                }
                
                let finalPosition = position + (impulseVector * 0.5)
                
                debrisPool.spawn(at: finalPosition, velocity: finalVelocity)
            }
        }
    
    private func performCollisionCheck(satPos: [SIMD3<Float>], satVel: [SIMD3<Float>], satIdx: [Int]) -> (deaths: [Int], explosions: [CollisionEvent]) {
        
        let satCount = satPos.count
        
        grid.clear()
        for i in 0..<satCount {
            grid.add(objectIndex: i, position: satPos[i])
        }
        
        for i in 0..<debrisPool.activeCount {
            let pos = debrisPool.position(at: i)
            grid.add(objectIndex: satCount + i, position: pos)
        }
        
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
        
        final class ThreadResult: @unchecked Sendable {
            var explosions: [CollisionEvent] = []
            var deaths: [Int] = []
            var debrisKills: [Int] = []
        }
        
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let buckets = (0..<coreCount).map { _ in ThreadResult() }
        
        DispatchQueue.concurrentPerform(iterations: coreCount) { coreIndex in
            let stepSize = coreCount
            var localExplosions: [CollisionEvent] = []
            var localDeaths: [Int] = []
            var localDebrisKills: [Int] = []
            
            for i in stride(from: coreIndex, to: satCount, by: stepSize) {
                let posA = satPos[i]
                let cellID = localGrid.getCellIndex(for: posA)
                if cellID == -1 { continue }
                
                for offset in localGrid.neighborOffsets {
                    let targetCell = cellID + offset
                    var neighborIdx = localGrid.firstObject(inCell: targetCell)
                    
                    while neighborIdx != -1 {
                        if neighborIdx > i {
                            var posB: SIMD3<Float> = .zero
                            var velB: SIMD3<Float> = .zero
                            var isDebris = false
                            
                            if neighborIdx < satCount {
                                posB = satPos[neighborIdx]
                                velB = satVel[neighborIdx]
                            } else {
                                let dIdx = neighborIdx - satCount
                                if dIdx < dActive {
                                    posB = SIMD3(dPosX[dIdx], dPosY[dIdx], dPosZ[dIdx])
                                    velB = SIMD3(dVelX[dIdx], dVelY[dIdx], dVelZ[dIdx])
                                    isDebris = true
                                } else {
                                    neighborIdx = localGrid.nextObject(after: neighborIdx)
                                    continue
                                }
                            }
                            
                            if abs(posA.x - posB.x) <= radius &&
                               abs(posA.y - posB.y) <= radius &&
                               abs(posA.z - posB.z) <= radius {
                                
                                if length_squared(posA - posB) < radiusSq {
                                    localDeaths.append(satIdx[i])
                                    localExplosions.append(CollisionEvent(position: posA, velocity: satVel[i]))
                                    
                                    if isDebris {
                                        localDebrisKills.append(neighborIdx - satCount)
                                        localExplosions.append(CollisionEvent(position: posB, velocity: velB))
                                    } else {
                                        localDeaths.append(satIdx[neighborIdx])
                                        localExplosions.append(CollisionEvent(position: posB, velocity: velB))
                                    }
                                }
                            }
                        }
                        neighborIdx = localGrid.nextObject(after: neighborIdx)
                    }
                }
            }
            
            let bucket = buckets[coreIndex]
            bucket.explosions = localExplosions
            bucket.deaths = localDeaths
            bucket.debrisKills = localDebrisKills
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
