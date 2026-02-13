import simd
import Combine
import UIKit
import RealityKit

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

struct SpatialGrid {
    private var headCell: ContiguousArray<Int32>
    private var nextParticle: ContiguousArray<Int32>
    private var usedCells: [Int] = []
    
    let neighborOffsets: [Int]
    
    let gridSize: Int = 64
    let shiftY: Int = 6
    let shiftZ: Int = 12
    let mask: Int = 63
    
    let offset: Float
    let cellSize: Float
    let inverseCellSize: Float
    let cellCount: Int
    
    init(maxObjects: Int, cellSize: Float = 10.0) {
        self.cellSize = cellSize
        self.inverseCellSize = 1.0 / cellSize
        self.offset = (Float(128) * cellSize) / 2.0
        self.cellCount = 128 * 128 * 128
        
        self.headCell = ContiguousArray(repeating: -1, count: cellCount)
        self.nextParticle = ContiguousArray(repeating: -1, count: maxObjects)
        self.usedCells.reserveCapacity(maxObjects)
        
        var offsets: [Int] = []
        offsets.reserveCapacity(27)
        let gs = 128
        let gs2 = 128 * 128
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    offsets.append(x + (y * gs) + (z * gs2))
                }
            }
        }
        self.neighborOffsets = offsets
    }
    
    mutating func clear() {
        for cellIndex in usedCells {
            headCell[cellIndex] = -1
        }
        usedCells.removeAll(keepingCapacity: true)
    }
    
    mutating func add(objectIndex: Int, position: SIMD3<Float>) {
        let cellID = getCellIndex(for: position)
        if cellID != -1 {
            if headCell[cellID] == -1 {
                usedCells.append(cellID)
            }
            nextParticle[objectIndex] = headCell[cellID]
            headCell[cellID] = Int32(objectIndex)
        }
    }
    
    @inline(__always)
    func getCellIndex(for position: SIMD3<Float>) -> Int {
        let x = Int((position.x + offset) * inverseCellSize)
        let y = Int((position.y + offset) * inverseCellSize)
        let z = Int((position.z + offset) * inverseCellSize)
        
        if x & ~mask == 0 && y & ~mask == 0 && z & ~mask == 0 {
            return x | (y << shiftY) | (z << shiftZ)
        }
        return -1
    }
    
    @inline(__always)
    func firstObject(inCell cellIndex: Int) -> Int {
        if cellIndex >= 0 && cellIndex < cellCount { return Int(headCell[cellIndex]) }
        return -1
    }
    
    @inline(__always)
    func nextObject(after objectIndex: Int) -> Int {
        return Int(nextParticle[objectIndex])
    }
}

class PhysicsEngine: ObservableObject {
    
    private let threadLock = NSLock()
    private var commandQueue: [EngineCommand] = []
    var isPaused: Bool = false
    @Published var simulationStats = SimStats()
    
    weak var arView: ARView?
    let rootAnchor = AnchorEntity(world: .zero)
    var earthEntity: Entity?
    let mainSun = DirectionalLight()
    var fillLight: DirectionalLight?
    let cameraPivot = Entity()
    let cameraEntity = Entity()
    
    
    private let standardSatMaterial = UnlitMaterial(color: .systemPink)
    private let standardDebrisMaterials = [
        UnlitMaterial(color: .gray),
        UnlitMaterial(color: .lightGray),
        UnlitMaterial(color: .white)
    ]
    
    private let highContrastSatMaterial = UnlitMaterial(color: .systemPink)
    private let highContrastDebrisMaterial = UnlitMaterial(color: .systemIndigo)
    
    var satelliteMaterial: Material
    var debrisMaterials: [Material]
    
    var satellites: [ModelEntity] = []
    var debrisPool: DebrisPool!
    private var grid: SpatialGrid
    
    private var satPosCache: [SIMD3<Float>] = []
    private var satVelCache: [SIMD3<Float>] = []
    
    struct CollisionEvent {
        let position: SIMD3<Float>
        let velocity: SIMD3<Float>
    }
    
    var settings = SimSettings()
    var frameCounter = 0
    
    var cameraZoomLevel: Float = 350.0
    var cameraAngleX: Float = -0.35
    var cameraAngleY: Float = 3.25
    private var isSettingsOpen: Bool = false
    
    var debrisMeshes: [MeshResource] = []
    var satelliteMesh: MeshResource
    
    let earthRadius: Float = 100.0
    let gravitationalConstant: Float = 1.0
    let earthMass: Float = 50000
    
    let debrisRotationDelta = simd_quatf(angle: 0.05, axis: [1, 0, 0])
    var killRadiusSq: Float = 0
    let maxRadiusSq: Float = 250.0 * 250.0
    
    private var sceneUpdateSubscription: Cancellable?
    
    init() {
        OrbitalData.registerComponent()
        
        self.grid = SpatialGrid(maxObjects: 3_500, cellSize: 10.0)
        self.killRadiusSq = pow(earthRadius + 2.0, 2)
        
        self.satelliteMaterial = standardSatMaterial
        self.debrisMaterials = standardDebrisMaterials
        
        satelliteMesh = .generateBox(size: 1.2)
        
        debrisMeshes = [
            Self.generateDebrisPyramid(size: 0.5),
            Self.generateDebrisPyramid(size: 0.6),
            Self.generateDebrisPyramid(size: 0.7)
        ]
        
        self.debrisPool = DebrisPool(capacity: 3_000, prototypeMeshes: debrisMeshes, materials: standardDebrisMaterials)
    }
    
    static func generateDebrisPyramid(size: Float) -> MeshResource {
        let halfSize = size / 2
        let height = size
        
        let yBase = -(height * 0.25)
        let yTip = height * 0.75
        
        let tipVertex = SIMD3<Float>(0, yTip, 0)
        let baseVertex1 = SIMD3<Float>(-halfSize, yBase, halfSize)
        let baseVertex2 = SIMD3<Float>(halfSize, yBase, halfSize)
        let baseVertex3 = SIMD3<Float>(halfSize, yBase, -halfSize)
        let baseVertex4 = SIMD3<Float>(-halfSize, yBase, -halfSize)
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        func addTriangleFace(_ p1: SIMD3<Float>, _ p2: SIMD3<Float>, _ p3: SIMD3<Float>) {
            let startIndex = UInt32(positions.count)
            positions.append(contentsOf: [p1, p2, p3])
            indices.append(contentsOf: [startIndex, startIndex + 1, startIndex + 2])
            let faceNormal = normalize(cross(p2 - p1, p3 - p1))
            normals.append(contentsOf: [faceNormal, faceNormal, faceNormal])
        }
        
        addTriangleFace(tipVertex, baseVertex1, baseVertex2)
        addTriangleFace(tipVertex, baseVertex2, baseVertex3)
        addTriangleFace(tipVertex, baseVertex3, baseVertex4)
        addTriangleFace(tipVertex, baseVertex4, baseVertex1)
        addTriangleFace(baseVertex1, baseVertex4, baseVertex3)
        addTriangleFace(baseVertex1, baseVertex3, baseVertex2)
        
        var descriptor = MeshDescriptor(name: "DebrisPyramid")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        
        return try! MeshResource.generate(from: [descriptor])
    }
    
    private func spawnExplosion(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
        if debrisPool.activeCount >= settings.maxDebris { return }
        
        let debrisCount = min(Int(settings.debrisPerCollision), 20)
        let explosionImpulse = Float(settings.explosionForce) * 3.0
        
        let velocityDirection = normalize(velocity)
        let radialDirection = normalize(position)
        let normalDirection = normalize(cross(velocityDirection, radialDirection))
        
        let scaleTangential = Float(settings.spreadTangential) * 0.1
        let scaleVertical = Float(settings.spreadVertical) * 1.5
        let scaleRadial = Float(settings.spreadRadial) * 0.05
        
        for _ in 0...debrisCount {
            if debrisPool.activeCount >= settings.maxDebris { break }
            
            let randomTangential = Float.random(in: -1...1) * scaleTangential
            let randomVertical = Float.random(in: -1...1) * scaleVertical
            let randomRadial = Float.random(in: -1...1) * scaleRadial
            
            let impulseVector = (velocityDirection * randomTangential) +
            (normalDirection * randomVertical) +
            (radialDirection * randomRadial)
            
            let speedVariance = Float.random(in: 0.8...1.2)
            let finalVelocity = velocity + (impulseVector * explosionImpulse * speedVariance)
            let finalPosition = position + (impulseVector * 1.2)
            
            debrisPool.spawn(
                at: finalPosition,
                velocity: finalVelocity,
                orientation: simd_quatf(angle: Float.random(in: 0...3), axis: [1, 1, 0]),
                scale: Float(settings.debrisScale)
            )
        }
    }
    
    func runSimulationFrame() {
        processCommandQueue()
        
        if isPaused { return }
        
        let gravityMult = Float(settings.gravityMultiplier)
        let deltaTime = (1.0 / 600.0) * Float(settings.timeScale)
        let earthMassVal = earthMass * gravityMult
        
        updateSatellites(dt: deltaTime, earthMass: earthMassVal)
        updateDebrisFast(dt: deltaTime, earthMass: earthMassVal)
        updateEarthRotation()
        detectCollisions()
        
        frameCounter += 1
        if frameCounter % 15 == 0 { publishStats() }
    }
    
    
    func updateSatellites(dt: Float, earthMass: Float) {
        let satScale = Float(settings.satelliteScale)
        let showModels = settings.showSatellites
        
        for i in (0..<satellites.count).reversed() {
            let entity = satellites[i]
            guard var data = entity.components[OrbitalData.self] else { continue }
            
            if !entity.isEnabled {
                entity.removeFromParent()
                satellites.remove(at: i)
                continue
            }
            
            let hasModel = entity.components.has(ModelComponent.self)
            if showModels && !hasModel {
                entity.components.set(ModelComponent(mesh: satelliteMesh, materials: [satelliteMaterial]))
            } else if !showModels && hasModel {
                entity.components.remove(ModelComponent.self)
            }
            if entity.scale.x != satScale { entity.scale = [satScale, satScale, satScale] }
            
            let pos = entity.position
            let distSq = length_squared(pos)
            let gravityAcceleration = pos * (-earthMass / (distSq * sqrt(distSq)))
            
            data.velocity += gravityAcceleration * dt
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }
    
    func updateDebrisFast(dt: Float, earthMass: Float) {
        let scale = Float(settings.debrisScale)
        let rotDelta = debrisRotationDelta
        
        debrisPool.updatePhysics(
            dt: dt,
            earthMass: earthMass,
            killRadiusSq: killRadiusSq,
            maxRadiusSq: maxRadiusSq,
            scale: scale,
            rotDelta: rotDelta
        )
        
        if debrisPool.activeCount > settings.maxDebris {
            let excess = debrisPool.activeCount - settings.maxDebris
            for _ in 0..<excess { debrisPool.kill(at: 0) }
        }
    }
    
    func detectCollisions() {
        if frameCounter % 2 != 0 { return }
        
        let satCount = satellites.count
        let totalCount = satCount + debrisPool.activeCount
        if totalCount == 0 { return }
        
        satPosCache.removeAll(keepingCapacity: true)
        satVelCache.removeAll(keepingCapacity: true)
        
        var activeSatIndices: [Int] = []
        activeSatIndices.reserveCapacity(satCount)
        
        for i in 0..<satCount {
            let sat = satellites[i]
            if sat.isEnabled {
                satPosCache.append(sat.position)
                satVelCache.append(sat.components[OrbitalData.self]?.velocity ?? .zero)
                activeSatIndices.append(i)
            }
        }
        
        grid.clear()
        
        for i in 0..<satPosCache.count {
            grid.add(objectIndex: i, position: satPosCache[i])
        }
        
        debrisPool.positions.withUnsafeBufferPointer { posPtr in
            for i in 0..<debrisPool.activeCount {
                grid.add(objectIndex: satPosCache.count + i, position: posPtr[i])
            }
        }
        
        let collisionLock = NSLock()
        var deaths: [Int] = []
        var debrisKills: [Int] = []
        var explosions: [CollisionEvent] = []
        
        let radius = Float(settings.collisionRadius)
        let radiusSq = radius * radius
        let cacheCount = satPosCache.count
        
        debrisPool.positions.withUnsafeBufferPointer { debrisPosPtr in
            debrisPool.velocities.withUnsafeBufferPointer { debrisVelPtr in
                
                DispatchQueue.concurrentPerform(iterations: cacheCount) { i in
                    let posA = satPosCache[i]
                    let cellID = grid.getCellIndex(for: posA)
                    if cellID == -1 { return }
                    
                    for offset in grid.neighborOffsets {
                        let targetCell = cellID + offset
                        var neighborIdx = grid.firstObject(inCell: targetCell)
                        
                        while neighborIdx != -1 {
                            
                            if neighborIdx > i {
                                var posB: SIMD3<Float> = .zero
                                var velB: SIMD3<Float> = .zero
                                var isDebris = false
                                
                                if neighborIdx < cacheCount {
                                    posB = satPosCache[neighborIdx]
                                    velB = satVelCache[neighborIdx]
                                } else {
                                    let dIdx = neighborIdx - cacheCount
                                    if dIdx < debrisPool.activeCount {
                                        posB = debrisPosPtr[dIdx]
                                        velB = debrisVelPtr[dIdx]
                                        isDebris = true
                                    } else {
                                        neighborIdx = grid.nextObject(after: neighborIdx)
                                        continue
                                    }
                                }
                                
                                let deltaX = abs(posA.x - posB.x)
                                if deltaX <= radius {
                                    let deltaY = abs(posA.y - posB.y)
                                    if deltaY <= radius {
                                        let deltaZ = abs(posA.z - posB.z)
                                        if deltaZ <= radius {
                                            
                                            if length_squared(posA - posB) < radiusSq {
                                                collisionLock.lock()
                                                
                                                deaths.append(activeSatIndices[i])
                                                explosions.append(CollisionEvent(position: posA, velocity: satVelCache[i]))
                                                
                                                if isDebris {
                                                    debrisKills.append(neighborIdx - cacheCount)
                                                    explosions.append(CollisionEvent(position: posB, velocity: velB))
                                                } else {
                                                    deaths.append(activeSatIndices[neighborIdx])
                                                    explosions.append(CollisionEvent(position: posB, velocity: velB))
                                                }
                                                
                                                collisionLock.unlock()
                                            }
                                        }
                                    }
                                }
                            }
                            neighborIdx = grid.nextObject(after: neighborIdx)
                        }
                    }
                }
            }
        }
        
        for satIndex in deaths {
            if satIndex < satellites.count && satellites[satIndex].isEnabled {
                satellites[satIndex].isEnabled = false
            }
        }
        
        let uniqueDebrisKills = Set(debrisKills).sorted(by: >)
        for debrisIndex in uniqueDebrisKills {
            debrisPool.kill(at: debrisIndex)
        }
        
        for boom in explosions {
            spawnExplosion(at: boom.position, velocity: boom.velocity)
        }
    }
    
    func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        debrisPool.reset()
        grid.clear()
        
        let orbitAlt = Float(settings.orbitAltitude)
        let gravityMult = Float(settings.gravityMultiplier)
        
        var spawnedPositions: [SIMD3<Float>] = []
        spawnedPositions.reserveCapacity(satelliteCount)
        let minSpawnDistance: Float = 2.5
        
        for _ in 0..<satelliteCount {
            var validPosition = false
            var attempts = 0
            var finalPos: SIMD3<Float> = .zero
            var finalVel: SIMD3<Float> = .zero
             
            while !validPosition && attempts < 10 {
                attempts += 1
                
                let anomaly = Float.random(in: 0...(2 * .pi))
                let raan = Float.random(in: 0...(2 * .pi))
                
                let inclination = settings.useRandomInclination
                ? Float.random(in: 0...(.pi))
                : 0
                
                let radius = orbitAlt + Float.random(in: -8.0...8.0)
                let x = radius * cos(anomaly)
                let z = radius * sin(anomaly)
                
                let orbitalSpeed = sqrt((gravitationalConstant * earthMass * gravityMult) / radius)
                let vx = -sin(anomaly) * orbitalSpeed
                let vz = cos(anomaly) * orbitalSpeed
                
                let rotInclination = simd_quatf(angle: inclination, axis: [1, 0, 0])
                let rotRAAN = simd_quatf(angle: raan, axis: [0, 1, 0])
                let combinedRotation = rotRAAN * rotInclination
                
                let candidatePos = combinedRotation.act(SIMD3<Float>(x, 0, z))
                let candidateVel = combinedRotation.act(SIMD3<Float>(vx, 0, vz))
                
                validPosition = true
                for existing in spawnedPositions {
                    if distance(existing, candidatePos) < minSpawnDistance {
                        validPosition = false
                        break
                    }
                }
                
                if validPosition || attempts == 10 {
                    finalPos = candidatePos
                    finalVel = candidateVel
                }
            }
            
            spawnedPositions.append(finalPos)
            
            let entity = ModelEntity(mesh: satelliteMesh, materials: [satelliteMaterial])
            let scale = Float(settings.satelliteScale)
            entity.scale = [scale, scale, scale]
            entity.position = finalPos
            
            entity.components.set(OrbitalData(velocity: finalVel, radius: 0.5 * scale, type: .leo))
            
            rootAnchor.addChild(entity)
            satellites.append(entity)
        }
    }
    
    func processCommandQueue() {
        threadLock.lock()
        let commands = commandQueue
        commandQueue.removeAll()
        threadLock.unlock()
        
        for command in commands {
            switch command {
            case .reset(let count): resetUniverse(satelliteCount: count)
            case .detonate: triggerRandomExplosion()
            case .updateSettings(let newSettings):
                let contrastChanged = (self.settings.highContrast != newSettings.highContrast)
                let earthChanged = (self.settings.showEarth != newSettings.showEarth)
                
                self.settings = newSettings
                updateLighting()
                
                if contrastChanged { updateHighContrastMode() }
                if earthChanged { earthEntity?.isEnabled = newSettings.showEarth }
            }
        }
    }
    
    func publishStats() {
        let stats = SimStats(debris: debrisPool.activeCount, satellites: satellites.count)
        DispatchQueue.main.async { self.simulationStats = stats }
    }
    
    func queueCommand(_ command: EngineCommand) {
        threadLock.lock()
        commandQueue.append(command)
        threadLock.unlock()
    }
    
    func triggerRandomExplosion() {
        let activeSats = satellites.filter { $0.isEnabled }
        if let victim = activeSats.randomElement(),
           let data = victim.components[OrbitalData.self] {
            victim.isEnabled = false
            spawnExplosion(at: victim.position, velocity: data.velocity)
        }
    }
    
    func updateHighContrastMode() {
        guard let arView = arView else { return }
        let isHighContrast = settings.highContrast
        
        DispatchQueue.main.async {
            arView.environment.background = isHighContrast ? .color(.white) : .color(.black)
        }
        
        let activeSatMat = isHighContrast ? highContrastSatMaterial : standardSatMaterial
        let activeDebrisMats = isHighContrast ? [highContrastDebrisMaterial] : standardDebrisMaterials
        
        self.satelliteMaterial = activeSatMat
        self.debrisMaterials = activeDebrisMats
        
        for sat in satellites {
            if var model = sat.model {
                model.materials = [activeSatMat]
                sat.model = model
            }
        }
        
        for entity in debrisPool.entities {
            if var model = entity.model {
                let mat = activeDebrisMats.randomElement() ?? activeDebrisMats[0]
                model.materials = [mat]
                entity.model = model
            }
        }
    }
    
    func rotateCamera(deltaX: Float, deltaY: Float) {
        cameraAngleX += deltaX
        cameraAngleY += deltaY
        cameraAngleX = max(-1.4, min(1.4, cameraAngleX))
        updateCameraTransform()
    }
    
    func zoomCamera(scaleFactor: Float) {
        cameraZoomLevel /= scaleFactor
        cameraZoomLevel = max(120, min(800, cameraZoomLevel))
        updateCameraPosition(animated: false)
    }
    
    func setSidePanelOpen(_ isOpen: Bool) {
        self.isSettingsOpen = isOpen
        updateCameraPosition(animated: true)
    }
    
    private func updateCameraPosition(animated: Bool = false) {
        let targetX = isSettingsOpen ? (cameraZoomLevel * 0.20) : 0.0
        
        let targetTransform = Transform(
            scale: .one,
            rotation: .init(),
            translation: SIMD3<Float>(targetX, 0, cameraZoomLevel)
        )
        
        if animated {
            cameraEntity.move(to: targetTransform, relativeTo: cameraPivot, duration: 0.4, timingFunction: .easeInOut)
        } else {
            cameraEntity.transform = targetTransform
        }
    }
    
    func resetCamera() {
        let targetAngleX: Float = -0.35
        let targetAngleY: Float = 3.25
        let targetZoom: Float = 350.0
        
        self.cameraAngleX = targetAngleX
        self.cameraAngleY = targetAngleY
        self.cameraZoomLevel = targetZoom
        
        let targetX = isSettingsOpen ? (targetZoom * 0.20) : 0.0
        
        let rotationY = simd_quatf(angle: targetAngleY, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: targetAngleX, axis: [1, 0, 0])
        let targetOrientation = rotationY * rotationX
        
        let targetCameraTransform = Transform(scale: .one, rotation: .init(), translation: [targetX, 0, targetZoom])
        
        cameraPivot.move(to: Transform(rotation: targetOrientation), relativeTo: rootAnchor, duration: 1.5, timingFunction: .easeInOut)
        cameraEntity.move(to: targetCameraTransform, relativeTo: cameraPivot, duration: 1.5, timingFunction: .easeInOut)
    }
    
    private func updateCameraTransform() {
        let rotationY = simd_quatf(angle: cameraAngleY, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: cameraAngleX, axis: [1, 0, 0])
        cameraPivot.orientation = rotationY * rotationX
    }
    
    func attach(to view: ARView) {
        self.arView = view
        
        view.debugOptions.insert(.showStatistics)
        
        if rootAnchor.children.isEmpty {
            mainSun.light.intensity = 5000
            mainSun.look(at: [0,0,0], from: [0, 50, -500], relativeTo: nil)
            rootAnchor.addChild(mainSun)
            
            let ambientLight = PointLight()
            ambientLight.light.intensity = 500
            ambientLight.position = [0, 100, 0]
            rootAnchor.addChild(ambientLight)
            
            setupEarth()
            setupCamera()
            updateLighting()
            
            for entity in debrisPool.entities {
                rootAnchor.addChild(entity)
            }
        }
        
        rootAnchor.removeFromParent()
        view.scene.addAnchor(rootAnchor)
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.runSimulationFrame()
        }
    }
    
    func updateLighting() {
        if settings.useOmniLight {
            if fillLight == nil {
                let fill = DirectionalLight()
                fill.light.intensity = 4000
                fill.look(at: [0,0,0], from: [0, 50, 500], relativeTo: nil)
                rootAnchor.addChild(fill)
                self.fillLight = fill
            }
        } else {
            if let fill = fillLight {
                fill.removeFromParent()
                self.fillLight = nil
            }
        }
    }
    
    func setupEarth() {
        let earthMesh = MeshResource.generateSphere(radius: earthRadius)
        var earthMaterial = PhysicallyBasedMaterial()
        
        earthMaterial.roughness = .init(floatLiteral: 0.8)
        earthMaterial.metallic = .init(floatLiteral: 0.0)
        earthMaterial.specular = .init(floatLiteral: 0.1)
        
        if let texture = try? TextureResource.load(named: "earthTopographicMap") {
            earthMaterial.baseColor = .init(texture: .init(texture))
        } else {
            earthMaterial.baseColor = .init(tint: .systemBlue)
        }
        
        let earth = ModelEntity(mesh: earthMesh, materials: [earthMaterial])
        
        let axialTilt = simd_quatf(angle: 23.5 * .pi / 180, axis: [0, 0, 1])
        earth.orientation = axialTilt
        
        self.earthEntity = earth
        rootAnchor.addChild(earth)
        
        let atmosphereMesh = MeshResource.generateSphere(radius: earthRadius + 2.0)
        var atmosphereMaterial = PhysicallyBasedMaterial()
        let atmColor = UIColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.3)
        atmosphereMaterial.baseColor = .init(tint: atmColor)
        atmosphereMaterial.roughness = .init(floatLiteral: 1.0)
        atmosphereMaterial.metallic = .init(floatLiteral: 0.0)
        atmosphereMaterial.blending = .transparent(opacity: 0.25)
        
        let atmosphere = ModelEntity(mesh: atmosphereMesh, materials: [atmosphereMaterial])
        atmosphere.components.set(OpacityComponent(opacity: 0.5))
        earth.addChild(atmosphere)
    }
    
    func updateEarthRotation() {
        guard let earth = earthEntity else { return }
        let deltaTime = (1.0 / 600.0) * Float(settings.timeScale)
        let rotationSpeed: Float = 0.2
        earth.orientation *= simd_quatf(angle: rotationSpeed * deltaTime, axis: [0, 1, 0])
    }
    
    func setupCamera() {
        cameraEntity.components.set(PerspectiveCameraComponent(near: 0.1, far: 3000))
        rootAnchor.addChild(cameraPivot)
        cameraPivot.addChild(cameraEntity)
        updateCameraTransform()
        cameraEntity.position.z = cameraZoomLevel
    }
}
