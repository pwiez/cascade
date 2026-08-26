//
//  PhysicsSolver.swift
//  Cascade
//
//  Created by Pedro Wiezel on 10/02/26.
//

import Foundation
import simd

actor PhysicsSolver {

    private let _executor = DispatchSerialExecutor(label: "com.pwiez.cascade.physics")
    nonisolated var unownedExecutor: UnownedSerialExecutor { _executor.asUnownedSerialExecutor() }

    private struct Hit {
        let index: Int
        let event: CollisionEvent
    }

    private final class ThreadResult: @unchecked Sendable {
        var satelliteHits: [Hit] = []
        var debrisHits: [Hit] = []

        func removeAll() {
            satelliteHits.removeAll(keepingCapacity: true)
            debrisHits.removeAll(keepingCapacity: true)
        }
    }

    private var threadBuckets: [ThreadResult]
    private var debrisPool: DebrisPool
    private var grid: SpatialGrid
    private var settings: EngineSettings

    private let killRadiusSq: Float
    private var maxRadiusSq: Float

    private var frameDeaths: [Int] = []
    private var frameExplosions: [CollisionEvent] = []
    private var killMask: ContiguousArray<Bool>

    private var frameBuffers: [FrameBuffer]
    private var bufferIndex = 0

    private var rng = FastRNG(seed: 0xC0FF_EE17)

    private static let lodSpinDistSq: Float = 700 * 700

    private static let objectsPerCore = 250

    private static let minGridWidth: Float = 1_500
    private static var minCellSize: Float { minGridWidth / Float(SpatialGrid.gridSize) }

    init(settings: EngineSettings, earthRadius: Float) {
        self.settings = settings

        let killRadius = earthRadius + 2.0
        self.killRadiusSq = killRadius * killRadius
        self.maxRadiusSq = Float(settings.sim.eliminationRadius * settings.sim.eliminationRadius)

        self.debrisPool = DebrisPool(capacity: Capacity.maxDebris)
        self.grid = SpatialGrid(
            maxObjects: Capacity.gridObjects,
            cellSize: Self.cellSize(forCollisionRadius: Float(settings.effectiveCollisionRadius))
        )

        self.threadBuckets = (0..<ProcessInfo.processInfo.activeProcessorCount).map { _ in
            let bucket = ThreadResult()
            bucket.satelliteHits.reserveCapacity(64)
            bucket.debrisHits.reserveCapacity(128)
            return bucket
        }

        self.killMask = ContiguousArray(repeating: false, count: Capacity.maxDebris)
        self.frameBuffers = [
            FrameBuffer(maxDebris: Capacity.maxDebris),
            FrameBuffer(maxDebris: Capacity.maxDebris)
        ]

        frameDeaths.reserveCapacity(200)
        frameExplosions.reserveCapacity(200)
    }

    private static func cellSize(forCollisionRadius radius: Float) -> Float {
        max(radius * 2.1, minCellSize)
    }

    // MARK: - Frame

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

        var killedSatellites: [Int] = []

        let worthChecking = (!satellitePositions.isEmpty && debrisPool.activeCount > 0)
            || satellitePositions.count > 1

        if worthChecking {
            killedSatellites = performCollisionCheck(
                satPos: satellitePositions,
                satVel: satelliteVelocities,
                satIdx: satelliteIndices
            )
        }

        let buffer = frameBuffers[bufferIndex]
        bufferIndex = 1 - bufferIndex
        computeVertices(into: buffer, cameraPosition: cameraPosition)

        return SimulationFrame(
            debrisCount: debrisPool.activeCount,
            vertexBuffer: buffer,
            killedSatelliteIndices: killedSatellites
        )
    }

    func updateSettings(_ newSettings: EngineSettings) {
        let newRadius = Float(newSettings.effectiveCollisionRadius)
        let newCellSize = Self.cellSize(forCollisionRadius: newRadius)

        if newCellSize != grid.cellSize {
            grid = SpatialGrid(maxObjects: Capacity.gridObjects, cellSize: newCellSize)
        }

        maxRadiusSq = Float(newSettings.sim.eliminationRadius * newSettings.sim.eliminationRadius)
        settings = newSettings
    }

    func reset() {
        debrisPool.reset()
        grid.clear()
    }

    // MARK: - Debris spawning

    func spawnExplosion(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
        guard debrisPool.activeCount < settings.maxDebris else { return }

        let fragments = min(settings.debrisPerCollision, 25)
        let force = Float(settings.sim.explosionForce) * 2.0

        let velocityDirection = Self.direction(of: velocity, fallback: SIMD3(0, 1, 0))
        let radialDirection = Self.direction(of: position, fallback: SIMD3(0, 1, 0))
        let normalDirection = Self.normalDirection(velocity: velocityDirection, radial: radialDirection)

        let scaleTangential = Float(settings.sim.spreadTangential)
        let scaleVertical = Float(settings.sim.spreadVertical) * 3.0
        let scaleRadial = Float(settings.sim.spreadRadial)

        for _ in 0..<fragments {
            guard debrisPool.activeCount < settings.maxDebris else { break }

            let impulse = (velocityDirection * (rng.nextSym() * 0.2 * scaleTangential))
                + (normalDirection * (rng.nextSym() * scaleVertical))
                + (radialDirection * (rng.nextSym() * 7.0 * scaleRadial))

            var finalVelocity = velocity + (impulse * force * rng.next(in: 0.8...1.4))

            let speed = length(finalVelocity)
            if speed < 10.0 {
                finalVelocity = speed > 1e-5
                    ? (finalVelocity / speed) * 12.0
                    : radialDirection * 12.0
            }

            debrisPool.spawn(at: position + (impulse * 0.5), velocity: finalVelocity)
        }
    }

    private static func direction(of vector: SIMD3<Float>, fallback: SIMD3<Float>) -> SIMD3<Float> {
        let magnitude = length(vector)
        return magnitude > 0.001 ? vector / magnitude : fallback
    }

    private static func normalDirection(velocity: SIMD3<Float>, radial: SIMD3<Float>) -> SIMD3<Float> {
        let crossed = cross(velocity, radial)
        guard length_squared(crossed) >= 0.0001 else {
            let arbitrary: SIMD3<Float> = abs(radial.x) < 0.9 ? SIMD3(1, 0, 0) : SIMD3(0, 1, 0)
            return normalize(cross(radial, arbitrary))
        }
        return normalize(crossed)
    }

    // MARK: - Vertex assembly

    private struct VertexContext: @unchecked Sendable {
        let verts: UnsafeMutableBufferPointer<DebrisVertex>
        let debris: DebrisPool.VertexBuffers
    }

    private func computeVertices(into buffer: FrameBuffer, cameraPosition: SIMD3<Float>) {
        let count = debrisPool.activeCount
        buffer.prepare(activeCount: count)

        let scale = Float(settings.sim.debrisScale)
        let corners = DebrisMesh.corners.map { $0 * scale }
        let spinEnabled = settings.sim.debrisRotation

        buffer.vertices.withUnsafeMutableBufferPointer { verts in
            debrisPool.withVertexBuffers { debrisBuffers in
                let context = VertexContext(verts: verts, debris: debrisBuffers)
                let chunkSize = 256
                let chunkCount = (count + chunkSize - 1) / chunkSize

                if chunkCount <= 1 {
                    Self.writeVertices(start: 0, end: count, context: context,
                                       spinEnabled: spinEnabled, camera: cameraPosition, corners: corners)
                } else {
                    DispatchQueue.concurrentPerform(iterations: chunkCount) { chunk in
                        let start = chunk * chunkSize
                        Self.writeVertices(start: start, end: min(start + chunkSize, count), context: context,
                                           spinEnabled: spinEnabled, camera: cameraPosition, corners: corners)
                    }
                }

                let staleStart = buffer.activeVertexCount
                let staleEnd = buffer.dirtyVertexCount
                if staleStart < staleEnd, let base = verts.baseAddress {
                    let stride = MemoryLayout<DebrisVertex>.stride
                    memset(UnsafeMutableRawPointer(base + staleStart), 0, (staleEnd - staleStart) * stride)
                }
            }
        }
    }

    private static func writeVertices(start: Int, end: Int,
                                      context: VertexContext,
                                      spinEnabled: Bool,
                                      camera: SIMD3<Float>,
                                      corners: [SIMD3<Float>]) {
        let debris = context.debris
        let verts = context.verts

        for i in start..<end {
            let position = SIMD3<Float>(debris.posX[i], debris.posY[i], debris.posZ[i])
            let base = i * DebrisMesh.verticesPerFragment
            let spin = spinEnabled && length_squared(position - camera) < lodSpinDistSq

            if spin {
                let axis = SIMD3<Float>(debris.rotAxisX[i], debris.rotAxisY[i], debris.rotAxisZ[i])
                let rotation = simd_float3x3(simd_quatf(angle: debris.rotAngle[i], axis: axis))
                for corner in 0..<DebrisMesh.verticesPerFragment {
                    verts[base + corner] = position + rotation * corners[corner]
                }
            } else {
                for corner in 0..<DebrisMesh.verticesPerFragment {
                    verts[base + corner] = position + corners[corner]
                }
            }
        }
    }

    // MARK: - Collisions

    private struct CollisionContext: @unchecked Sendable {
        let satPos: UnsafeBufferPointer<SIMD3<Float>>
        let satVel: UnsafeBufferPointer<SIMD3<Float>>
        let satIdx: UnsafeBufferPointer<Int>
        let debris: DebrisPool.CollisionBuffers
    }

    private func performCollisionCheck(satPos: [SIMD3<Float>],
                                       satVel: [SIMD3<Float>],
                                       satIdx: [Int]) -> [Int] {
        let satCount = satPos.count
        let debrisCount = debrisPool.activeCount

        grid.clear()
        for i in 0..<satCount {
            grid.add(objectIndex: i, position: satPos[i])
        }
        for i in 0..<debrisCount {
            grid.add(objectIndex: satCount + i, position: debrisPool.position(at: i))
        }

        let radius = Float(settings.effectiveCollisionRadius)
        let satRadius = radius * 2.0

        let localGrid = grid
        let workerCount = min(
            max(1, (satCount + debrisCount) / Self.objectsPerCore),
            threadBuckets.count
        )
        let buckets = threadBuckets

        for bucket in buckets {
            bucket.removeAll()
        }

        satPos.withUnsafeBufferPointer { ptrSatPos in
        satVel.withUnsafeBufferPointer { ptrSatVel in
        satIdx.withUnsafeBufferPointer { ptrSatIdx in
        debrisPool.withCollisionBuffers { debrisBuffers in

            let context = CollisionContext(
                satPos: ptrSatPos, satVel: ptrSatVel, satIdx: ptrSatIdx, debris: debrisBuffers
            )
            let chunk = max(1, (satCount + workerCount - 1) / workerCount)

            DispatchQueue.concurrentPerform(iterations: workerCount) { worker in
                let bucket = buckets[worker]
                let start = min(worker * chunk, satCount)
                let end = min(start + chunk, satCount)

                for i in start..<end {
                    Self.testSatellite(
                        i, against: localGrid, context: context,
                        satCount: satCount, debrisCount: debrisCount,
                        radius: radius, satRadius: satRadius,
                        into: bucket
                    )
                }
            }
        }}}}

        reduce(buckets, debrisCount: debrisCount)
        return frameDeaths
    }

    private func reduce(_ buckets: [ThreadResult], debrisCount: Int) {
        frameDeaths.removeAll(keepingCapacity: true)
        frameExplosions.removeAll(keepingCapacity: true)

        var deadSatellites = Set<Int>()

        for bucket in buckets {
            for hit in bucket.satelliteHits where deadSatellites.insert(hit.index).inserted {
                frameDeaths.append(hit.index)
                frameExplosions.append(hit.event)
            }
            for hit in bucket.debrisHits where hit.index < debrisCount && !killMask[hit.index] {
                killMask[hit.index] = true
                frameExplosions.append(hit.event)
            }
        }

        var i = debrisCount - 1
        while i >= 0 {
            if killMask[i] {
                killMask[i] = false
                debrisPool.kill(at: i)
            }
            i -= 1
        }

        for explosion in frameExplosions {
            spawnExplosion(at: explosion.position, velocity: explosion.velocity)
        }
    }

    private static func testSatellite(_ i: Int,
                                      against grid: SpatialGrid,
                                      context: CollisionContext,
                                      satCount: Int, debrisCount: Int,
                                      radius: Float, satRadius: Float,
                                      into bucket: ThreadResult) {
        let posA = context.satPos[i]
        let cellID = grid.cellIndex(for: posA)
        guard cellID != -1 else { return }

        for offset in SpatialGrid.neighborOffsets {
            let neighborCell = grid.neighborCell(of: cellID, offset: offset)
            guard neighborCell != -1 else { continue }

            var neighbor = grid.firstObject(inCell: neighborCell)
            while neighbor != -1 {
                let candidate = neighbor
                neighbor = grid.nextObject(after: neighbor)

                guard candidate > i else { continue }

                let posB: SIMD3<Float>
                let velB: SIMD3<Float>
                let isDebris = candidate >= satCount

                if isDebris {
                    let d = candidate - satCount
                    guard d < debrisCount else { continue }
                    posB = SIMD3(context.debris.posX[d], context.debris.posY[d], context.debris.posZ[d])
                    velB = SIMD3(context.debris.velX[d], context.debris.velY[d], context.debris.velZ[d])
                } else {
                    posB = context.satPos[candidate]
                    velB = context.satVel[candidate]
                }

                let effectiveRadius = isDebris ? radius : satRadius
                let delta = abs(posA - posB)
                guard delta.x <= effectiveRadius,
                      delta.y <= effectiveRadius,
                      delta.z <= effectiveRadius,
                      length_squared(posA - posB) < effectiveRadius * effectiveRadius else { continue }

                bucket.satelliteHits.append(
                    Hit(index: context.satIdx[i], event: CollisionEvent(position: posA, velocity: context.satVel[i]))
                )

                let event = CollisionEvent(position: posB, velocity: velB)
                if isDebris {
                    bucket.debrisHits.append(Hit(index: candidate - satCount, event: event))
                } else {
                    bucket.satelliteHits.append(Hit(index: context.satIdx[candidate], event: event))
                }
            }
        }
    }
}
