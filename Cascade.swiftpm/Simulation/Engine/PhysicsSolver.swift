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

struct DebrisVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}

final class FrameBuffer: @unchecked Sendable {
    var vertices: ContiguousArray<DebrisVertex>
    var activeVertexCount: Int = 0
    var dirtyVertexCount: Int = 0
    private var lastWrittenCount: Int = 0

    init(maxDebris: Int) {
        let maxVerts = maxDebris * 4
        vertices = ContiguousArray(
            repeating: DebrisVertex(position: .zero, normal: .zero),
            count: maxVerts
        )
    }

    func prepare(activeCount: Int) {
        let activeVerts = activeCount * 4
        activeVertexCount = activeVerts
        dirtyVertexCount = max(activeVerts, lastWrittenCount)
        lastWrittenCount = activeVerts
    }
}

struct SimulationFrame: @unchecked Sendable {
    let count: Int
    let vertexBuffer: FrameBuffer
    let killedSatelliteIndices: [Int]
    let explosions: [CollisionEvent]
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

    private var frameDeaths: [Int] = []
    private var frameDebrisKills: [Int] = []
    private var frameExplosions: [CollisionEvent] = []

    private var frameBuffers: [FrameBuffer]
    private var bufferIndex: Int = 0

    private static let localVerts: [SIMD3<Float>] = [
        SIMD3(0, 0.5, 0), SIMD3(0.5, -0.5, 0.289),
        SIMD3(-0.5, -0.5, 0.289), SIMD3(0, -0.5, -0.577)
    ]

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

        frameDeaths.reserveCapacity(200)
        frameDebrisKills.reserveCapacity(200)
        frameExplosions.reserveCapacity(200)

        self.frameBuffers = [
            FrameBuffer(maxDebris: 5500),
            FrameBuffer(maxDebris: 5500)
        ]
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
            debrisPool.trimTo(settings.maxDebris)
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

        let buf = frameBuffers[bufferIndex]
        bufferIndex = 1 - bufferIndex
        computeVertices(into: buf)

        return SimulationFrame(
            count: debrisPool.activeCount,
            vertexBuffer: buf,
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
        let crossResult = cross(velocityDirection, radialDirection)
        let normalDirection: SIMD3<Float>
        if length_squared(crossResult) < 0.0001 {
            let arbitrary = abs(radialDirection.x) < 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)
            normalDirection = normalize(cross(radialDirection, arbitrary))
        } else {
            normalDirection = normalize(crossResult)
        }

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

    private func computeVertices(into buf: FrameBuffer) {
        let count = debrisPool.activeCount
        buf.prepare(activeCount: count)

        let scale = Float(settings.debrisScale)
        let spinEnabled = settings.debrisRotation
        let sv0 = Self.localVerts[0] * scale
        let sv1 = Self.localVerts[1] * scale
        let sv2 = Self.localVerts[2] * scale
        let sv3 = Self.localVerts[3] * scale
        let defaultNormal = SIMD3<Float>(0, 1, 0)

        buf.vertices.withUnsafeMutableBufferPointer { verts in
            if spinEnabled {
                for i in 0..<count {
                    let pos = debrisPool.position(at: i)
                    let axis = SIMD3<Float>(debrisPool.rotAxisX[i], debrisPool.rotAxisY[i], debrisPool.rotAxisZ[i])
                    let q = simd_quatf(angle: debrisPool.rotAngle[i], axis: axis)
                    let base = i * 4
                    verts[base    ] = DebrisVertex(position: pos + q.act(sv0), normal: defaultNormal)
                    verts[base + 1] = DebrisVertex(position: pos + q.act(sv1), normal: defaultNormal)
                    verts[base + 2] = DebrisVertex(position: pos + q.act(sv2), normal: defaultNormal)
                    verts[base + 3] = DebrisVertex(position: pos + q.act(sv3), normal: defaultNormal)
                }
            } else {
                for i in 0..<count {
                    let pos = debrisPool.position(at: i)
                    let base = i * 4
                    verts[base    ] = DebrisVertex(position: pos + sv0, normal: defaultNormal)
                    verts[base + 1] = DebrisVertex(position: pos + sv1, normal: defaultNormal)
                    verts[base + 2] = DebrisVertex(position: pos + sv2, normal: defaultNormal)
                    verts[base + 3] = DebrisVertex(position: pos + sv3, normal: defaultNormal)
                }
            }

            let staleStart = buf.activeVertexCount
            let staleEnd = buf.dirtyVertexCount
            if staleStart < staleEnd {
                let ptr = UnsafeMutableRawPointer(verts.baseAddress! + staleStart)
                memset(ptr, 0, (staleEnd - staleStart) * MemoryLayout<DebrisVertex>.stride)
            }
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
        let satRadius = radius * 2.0
        let satRadiusSq = satRadius * satRadius

        let localGrid = self.grid
        let dActive = debrisPool.activeCount

        let totalObjects = satCount + dActive
        let objectsPerCore = 250
        let desiredCores = max(1, totalObjects / objectsPerCore)
        let coreCount = min(desiredCores, threadBuckets.count)
        let buckets = threadBuckets

        for i in 0..<coreCount {
            buckets[i].explosions.removeAll(keepingCapacity: true)
            buckets[i].deaths.removeAll(keepingCapacity: true)
            buckets[i].debrisKills.removeAll(keepingCapacity: true)
        }

        struct CollisionPtrs: @unchecked Sendable {
            let satPos: UnsafeBufferPointer<SIMD3<Float>>
            let satVel: UnsafeBufferPointer<SIMD3<Float>>
            let satIdx: UnsafeBufferPointer<Int>
            let debris: DebrisPool.CollisionBuffers
        }

        satPos.withUnsafeBufferPointer { ptrSatPos in
        satVel.withUnsafeBufferPointer { ptrSatVel in
        satIdx.withUnsafeBufferPointer { ptrSatIdx in
        debrisPool.withCollisionBuffers { debrisBufs in

            let ptrs = CollisionPtrs(
                satPos: ptrSatPos, satVel: ptrSatVel, satIdx: ptrSatIdx,
                debris: debrisBufs
            )

            DispatchQueue.concurrentPerform(iterations: coreCount) { coreIndex in
                let bucket = buckets[coreIndex]

                for i in stride(from: coreIndex, to: satCount, by: coreCount) {
                    let posA = ptrs.satPos[i]
                    let cellID = localGrid.getCellIndex(for: posA)
                    guard cellID != -1 else { continue }

                    for offset in localGrid.neighborOffsets {
                        let neighborCellID = localGrid.neighborCell(of: cellID, offset: offset)
                        guard neighborCellID != -1 else { continue }
                        var neighborIdx = localGrid.firstObject(inCell: neighborCellID)

                        while neighborIdx != -1 {
                            let currentNeighbor = neighborIdx
                            neighborIdx = localGrid.nextObject(after: neighborIdx)

                            guard currentNeighbor > i else { continue }

                            let posB: SIMD3<Float>
                            let velB: SIMD3<Float>
                            let isDebris: Bool

                            if currentNeighbor < satCount {
                                posB = ptrs.satPos[currentNeighbor]
                                velB = ptrs.satVel[currentNeighbor]
                                isDebris = false
                            } else {
                                let dIdx = currentNeighbor - satCount
                                guard dIdx < dActive else { continue }
                                posB = SIMD3(ptrs.debris.posX[dIdx], ptrs.debris.posY[dIdx], ptrs.debris.posZ[dIdx])
                                velB = SIMD3(ptrs.debris.velX[dIdx], ptrs.debris.velY[dIdx], ptrs.debris.velZ[dIdx])
                                isDebris = true
                            }

                            let effectiveRadius = isDebris ? radius : satRadius
                            guard abs(posA.x - posB.x) <= effectiveRadius &&
                                    abs(posA.y - posB.y) <= effectiveRadius &&
                                    abs(posA.z - posB.z) <= effectiveRadius else { continue }

                            let effectiveRSq = isDebris ? radiusSq : satRadiusSq
                            guard length_squared(posA - posB) < effectiveRSq else { continue }

                            bucket.deaths.append(ptrs.satIdx[i])
                            bucket.explosions.append(CollisionEvent(position: posA, velocity: ptrs.satVel[i]))

                            if isDebris {
                                bucket.debrisKills.append(currentNeighbor - satCount)
                                bucket.explosions.append(CollisionEvent(position: posB, velocity: velB))
                            } else {
                                bucket.deaths.append(ptrs.satIdx[currentNeighbor])
                                bucket.explosions.append(CollisionEvent(position: posB, velocity: velB))
                            }
                        }
                    }
                }
            }
        }}}}

        frameDeaths.removeAll(keepingCapacity: true)
        frameDebrisKills.removeAll(keepingCapacity: true)
        frameExplosions.removeAll(keepingCapacity: true)

        for bucket in buckets {
            frameDeaths.append(contentsOf: bucket.deaths)
            frameDebrisKills.append(contentsOf: bucket.debrisKills)
            frameExplosions.append(contentsOf: bucket.explosions)
        }

        for debrisIndex in Set(frameDebrisKills).sorted(by: >) {
            debrisPool.kill(at: debrisIndex)
        }
        for boom in frameExplosions {
            spawnExplosion(at: boom.position, velocity: boom.velocity)
        }

        return (frameDeaths, frameExplosions)
    }
}
