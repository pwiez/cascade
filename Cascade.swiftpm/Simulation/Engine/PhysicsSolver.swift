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

typealias DebrisVertex = SIMD3<Float>

final class FrameBuffer: @unchecked Sendable {
    var vertices: ContiguousArray<DebrisVertex>
    var activeVertexCount: Int = 0
    var dirtyVertexCount: Int = 0
    private var lastWrittenCount: Int = 0

    init(maxDebris: Int) {
        let maxVerts = maxDebris * 4
        vertices = ContiguousArray(repeating: .zero, count: maxVerts)
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

struct FastRNG {
    var state: UInt32
    init(seed: UInt32) { self.state = seed == 0 ? 0xdeadbeef : seed }
    mutating func nextU32() -> UInt32 {
        var x = state
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        state = x
        return x
    }
    mutating func nextSym() -> Float {
        let v = Float(nextU32() >> 8) * (1.0 / 8388608.0)
        return v - 1.0
    }
    mutating func next(in range: ClosedRange<Float>) -> Float {
        let lo = range.lowerBound
        let hi = range.upperBound
        let v = Float(nextU32() >> 8) * (1.0 / 16777216.0)
        return lo + (hi - lo) * v
    }
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
    private var maxRadiusSq: Float
    private var settings: SimSettings

    private var frameDeaths: [Int] = []
    private var frameExplosions: [CollisionEvent] = []
    private var killMask: ContiguousArray<Bool>

    private var frameBuffers: [FrameBuffer]
    private var bufferIndex: Int = 0

    private var rng = FastRNG(seed: 0xC0FFEE17)

    private static let lodSpinDistSq: Float = 700 * 700

    private static let localVerts: [SIMD3<Float>] = [
        SIMD3(0, 1.125, 0), SIMD3(1.125, -1.125, 0.65025),
        SIMD3(-1.125, -1.125, 0.65025), SIMD3(0, -1.125, -1.299)
    ]

    init(settings: SimSettings, earthRadius: Float) {
        self.settings = settings
        self.killRadiusSq = pow(earthRadius + 2.0, 2)
        self.maxRadiusSq = pow(Float(settings.eliminationRadius), 2)

        self.debrisPool = DebrisPool(capacity: 8000)

        let minGridWidth: Float = 1500.0
        let requiredCellSize = minGridWidth / 128.0
        let safeCellSize = max(Float(settings.collisionRadius * 2.1), requiredCellSize)
        self.grid = SpatialGrid(maxObjects: 8500, cellSize: safeCellSize)

        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        self.threadBuckets = (0..<coreCount).map { _ in
            let bucket = ThreadResult()
            bucket.explosions.reserveCapacity(100)
            bucket.deaths.reserveCapacity(50)
            bucket.debrisKills.reserveCapacity(100)
            return bucket
        }

        frameDeaths.reserveCapacity(200)
        frameExplosions.reserveCapacity(200)
        self.killMask = ContiguousArray(repeating: false, count: 8000)

        self.frameBuffers = [
            FrameBuffer(maxDebris: 8000),
            FrameBuffer(maxDebris: 8000)
        ]
    }

    func step(dt: Float,
              earthMass: Float,
              satellitePositions: [SIMD3<Float>],
              satelliteVelocities: [SIMD3<Float>],
              satelliteIndices: [Int],
              cameraPosition: SIMD3<Float>) -> SimulationFrame {

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
        computeVertices(into: buf, cameraPosition: cameraPosition)

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
            let minGridWidth: Float = 1500.0
            let requiredCellSize = minGridWidth / 128.0
            let safeCellSize = max(newRadius * 2.1, requiredCellSize)
            self.grid = SpatialGrid(maxObjects: 8500, cellSize: safeCellSize)
        }

        self.maxRadiusSq = pow(Float(newSettings.eliminationRadius), 2)
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

            let rT = rng.nextSym() * 0.2 * scaleTangential
            let rV = rng.nextSym() * scaleVertical
            let rR = rng.nextSym() * 7.0 * scaleRadial

            let impulse = (velocityDirection * rT) +
            (normalDirection * rV) +
            (radialDirection * rR)

            let speedVariance = rng.next(in: 0.8...1.4)
            var finalVelocity = velocity + (impulse * explosionForce * speedVariance)

            if length(finalVelocity) < 10.0 {
                finalVelocity = normalize(finalVelocity) * 12.0
            }

            debrisPool.spawn(at: position + (impulse * 0.5), velocity: finalVelocity)
        }
    }

    private struct VertCtx: @unchecked Sendable {
        let verts: UnsafeMutableBufferPointer<DebrisVertex>
        let debris: DebrisPool.VertexBuffers
    }

    private func computeVertices(into buf: FrameBuffer, cameraPosition: SIMD3<Float>) {
        let count = debrisPool.activeCount
        buf.prepare(activeCount: count)

        let scale = Float(settings.debrisScale)
        let spinEnabled = settings.debrisRotation
        let sv0 = Self.localVerts[0] * scale
        let sv1 = Self.localVerts[1] * scale
        let sv2 = Self.localVerts[2] * scale
        let sv3 = Self.localVerts[3] * scale
        let lodSq = Self.lodSpinDistSq

        buf.vertices.withUnsafeMutableBufferPointer { verts in
            debrisPool.withVertexBuffers { debrisBufs in
                let ctx = VertCtx(verts: verts, debris: debrisBufs)

                let chunkSize = 256
                let chunkCount = (count + chunkSize - 1) / chunkSize

                if chunkCount <= 1 {
                    Self.writeVertices(
                        start: 0, end: count, ctx: ctx,
                        spinEnabled: spinEnabled, lodSq: lodSq,
                        camera: cameraPosition,
                        sv0: sv0, sv1: sv1, sv2: sv2, sv3: sv3
                    )
                } else {
                    DispatchQueue.concurrentPerform(iterations: chunkCount) { chunk in
                        let start = chunk * chunkSize
                        let end = min(start + chunkSize, count)
                        Self.writeVertices(
                            start: start, end: end, ctx: ctx,
                            spinEnabled: spinEnabled, lodSq: lodSq,
                            camera: cameraPosition,
                            sv0: sv0, sv1: sv1, sv2: sv2, sv3: sv3
                        )
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
    }

    private static func writeVertices(
        start: Int, end: Int,
        ctx: VertCtx,
        spinEnabled: Bool, lodSq: Float,
        camera: SIMD3<Float>,
        sv0: SIMD3<Float>, sv1: SIMD3<Float>, sv2: SIMD3<Float>, sv3: SIMD3<Float>
    ) {
        let d = ctx.debris
        let verts = ctx.verts
        for i in start..<end {
            let pos = SIMD3<Float>(d.posX[i], d.posY[i], d.posZ[i])
            let base = i * 4
            let dx = pos.x - camera.x
            let dy = pos.y - camera.y
            let dz = pos.z - camera.z
            let camDistSq = dx*dx + dy*dy + dz*dz

            if spinEnabled && camDistSq < lodSq {
                let axis = SIMD3<Float>(d.rotAxisX[i], d.rotAxisY[i], d.rotAxisZ[i])
                let m = simd_float3x3(simd_quatf(angle: d.rotAngle[i], axis: axis))
                verts[base    ] = pos + m * sv0
                verts[base + 1] = pos + m * sv1
                verts[base + 2] = pos + m * sv2
                verts[base + 3] = pos + m * sv3
            } else {
                verts[base    ] = pos + sv0
                verts[base + 1] = pos + sv1
                verts[base + 2] = pos + sv2
                verts[base + 3] = pos + sv3
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

            let chunkBase = max(1, (satCount + coreCount - 1) / coreCount)
            DispatchQueue.concurrentPerform(iterations: coreCount) { coreIndex in
                let bucket = buckets[coreIndex]
                let sStart = min(coreIndex * chunkBase, satCount)
                let sEnd = min(sStart + chunkBase, satCount)

                for i in sStart..<sEnd {
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
        frameExplosions.removeAll(keepingCapacity: true)

        let activeBefore = debrisPool.activeCount
        if killMask.count < activeBefore {
            killMask = ContiguousArray(repeating: false, count: max(activeBefore, 8000))
        }

        for bucket in buckets {
            frameDeaths.append(contentsOf: bucket.deaths)
            frameExplosions.append(contentsOf: bucket.explosions)
            for k in bucket.debrisKills where k < activeBefore {
                killMask[k] = true
            }
        }

        var i = activeBefore - 1
        while i >= 0 {
            if killMask[i] {
                killMask[i] = false
                debrisPool.kill(at: i)
            }
            i -= 1
        }

        for boom in frameExplosions {
            spawnExplosion(at: boom.position, velocity: boom.velocity)
        }

        return (frameDeaths, frameExplosions)
    }
}
