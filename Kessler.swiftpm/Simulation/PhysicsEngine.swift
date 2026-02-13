import Foundation
import RealityKit
import Combine
import UIKit
import simd

class DebrisPool {
    var positions: ContiguousArray<SIMD3<Float>>
    var velocities: ContiguousArray<SIMD3<Float>>
    var orientations: ContiguousArray<simd_quatf>
    var entities: ContiguousArray<ModelEntity>
    
    var activeCount: Int = 0
    let capacity: Int
    
    init(capacity: Int, prototypeMeshes: [MeshResource], materials: [UnlitMaterial]) {
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
    
    func updatePhysics(dt: Float, earthMass: Float, killRadiusSq: Float, scale: Float, rotDelta: simd_quatf) {
        
        positions.withUnsafeMutableBufferPointer { posPtr in
            velocities.withUnsafeMutableBufferPointer { velPtr in
                
                DispatchQueue.concurrentPerform(iterations: activeCount) { i in
                    let pos = posPtr[i]
                    let distSq = length_squared(pos)
                    
                    if distSq < killRadiusSq { return }
                    
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
            if length_squared(positions[i]) < killRadiusSq {
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
        
        for index in killList.reversed() {
            self.kill(at: index)
        }
    }
}

struct SpatialGrid {
    private var headCell: ContiguousArray<Int32>
    private var nextParticle: ContiguousArray<Int32>
    private var usedCells: [Int] = []
    
    let gridSize: Int = 128
    let shiftY: Int = 7
    let shiftZ: Int = 14
    let mask: Int = 127
    
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
    
    var satellites: [ModelEntity] = []
    
    var debrisPool: DebrisPool!
    private var grid: SpatialGrid
    
    var settings = SimSettings()
    var frameCounter = 0
    
    var cameraZoomLevel: Float = 350.0
    var cameraAngleX: Float = -0.35
    var cameraAngleY: Float = 3.25
    
    var debrisMeshes: [MeshResource] = []
    var satelliteMesh: MeshResource
    
    var debrisMaterials: [UnlitMaterial] = []
    var satelliteMaterial: PhysicallyBasedMaterial
    
    let earthRadius: Float = 100.0
    let gravitationalConstant: Float = 1.0
    let earthMass: Float = 50000
    
    let debrisRotationDelta = simd_quatf(angle: 0.05, axis: [1, 0, 0])
    var killRadiusSq: Float = 0
    
    private var sceneUpdateSubscription: Cancellable?
    
    init() {
        OrbitalData.registerComponent()
        
        self.grid = SpatialGrid(maxObjects: 3_500, cellSize: 10.0)
        
        self.killRadiusSq = pow(earthRadius + 2.0, 2)
        
        debrisMaterials = [
            UnlitMaterial(color: .gray),
            UnlitMaterial(color: .lightGray),
            UnlitMaterial(color: .white)
        ]
        
        satelliteMaterial = PhysicallyBasedMaterial()
        satelliteMaterial.baseColor = .init(tint: .purple)
        satelliteMaterial.metallic = .init(floatLiteral: 0.6)
        satelliteMaterial.roughness = .init(floatLiteral: 0.4)
        
        satelliteMesh = .generateBox(size: 0.75)
        debrisMeshes = [
            Self.generateDebrisPyramid(size: 0.35),
            Self.generateDebrisPyramid(size: 0.45),
            Self.generateDebrisPyramid(size: 0.55)
        ]
        
        self.debrisPool = DebrisPool(capacity: 3_000, prototypeMeshes: debrisMeshes, materials: debrisMaterials)
    }
    
    static func generateDebrisPyramid(size: Float) -> MeshResource {
        let halfSize = size / 2
        let height = size
        let yBase = -height / 2
        let yTip = height / 2
        
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
        if isPaused { return }
        
        processCommandQueue()
        
        let gravityMult = Float(settings.gravityMultiplier)
        let deltaTime = (1.0 / 60.0) * Float(settings.timeScale)
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
            scale: scale,
            rotDelta: rotDelta
        )
        
        let stride = 2
        let offset = frameCounter % stride
        
        let updateRotation = (frameCounter % 3 == 0)
        
        var i = offset
        while i < debrisPool.activeCount {
            let entity = debrisPool.entities[i]
            
            entity.position = debrisPool.positions[i]
            
            if updateRotation {
                debrisPool.orientations[i] *= rotDelta
                entity.orientation = debrisPool.orientations[i]
            }
            
            if frameCounter % 60 == 0 {
                if entity.scale.x != scale {
                    entity.scale = SIMD3<Float>(repeating: scale)
                }
            }
            
            i += stride
        }
        
        if debrisPool.activeCount > settings.maxDebris {
            let excess = debrisPool.activeCount - settings.maxDebris
            for _ in 0..<excess { debrisPool.kill(at: 0) }
        }
    }
    
    
    func detectCollisions() {
        if frameCounter % 2 != 0 { return }
        
        grid.clear()
        
        let satCount = satellites.count
        var activeSatellitesInGrid = 0
        
        for i in 0..<satCount {
            if satellites[i].isEnabled {
                grid.add(objectIndex: i, position: satellites[i].position)
                activeSatellitesInGrid += 1
            }
        }
        
        if activeSatellitesInGrid == 0 { return }
        
        debrisPool.positions.withUnsafeBufferPointer { posPtr in
            for i in 0..<debrisPool.activeCount {
                grid.add(objectIndex: satCount + i, position: posPtr[i])
            }
        }
        
        var confirmedCollisions: [(position: SIMD3<Float>, velocity: SIMD3<Float>)] = []
        let collisionLock = NSLock()
        
        let radius = Float(settings.collisionRadius)
        let thresholdSq = radius * radius
        
        let gs = grid.gridSize
        let gs2 = 128 * 128
        
        var neighborOffsets: [Int] = []
        neighborOffsets.reserveCapacity(27)
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    neighborOffsets.append(x + (y * gs) + (z * gs2))
                }
            }
        }
        
        debrisPool.positions.withUnsafeBufferPointer { debrisPosPtr in
            debrisPool.velocities.withUnsafeBufferPointer { debrisVelPtr in
                
                let collisionLock = NSLock()
                var localConfirmed: [(SIMD3<Float>, SIMD3<Float>)] = []
                let thresholdSq = Float(settings.collisionRadius * settings.collisionRadius)
                let radius = Float(settings.collisionRadius)
                
                let gs = grid.gridSize
                let gs2 = 128 * 128
                var neighborOffsets: [Int] = []
                neighborOffsets.reserveCapacity(27)
                for x in -1...1 {
                    for y in -1...1 {
                        for z in -1...1 { neighborOffsets.append(x + (y * gs) + (z * gs2)) }
                    }
                }
                
                DispatchQueue.concurrentPerform(iterations: satCount) { i in
                    let primary = satellites[i]
                    guard primary.isEnabled else { return }
                    
                    let primaryPos = primary.position
                    let cellID = grid.getCellIndex(for: primaryPos)
                    if cellID == -1 { return }
                    
                    for offset in neighborOffsets {
                        let targetCell = cellID + offset
                        var neighborIndex = grid.firstObject(inCell: targetCell)
                        
                        while neighborIndex != -1 {
                            if i != neighborIndex {
                                var neighborPos: SIMD3<Float> = .zero
                                var neighborVel: SIMD3<Float> = .zero
                                var isNeighborActive = false
                                var isNeighborSatellite = false
                                
                                if neighborIndex < satCount {
                                    let nSat = satellites[neighborIndex]
                                    if nSat.isEnabled {
                                        neighborPos = nSat.position
                                        neighborVel = nSat.components[OrbitalData.self]?.velocity ?? .zero
                                        isNeighborActive = true
                                        isNeighborSatellite = true
                                    }
                                } else {
                                    let debrisIdx = neighborIndex - satCount
                                    if debrisIdx < debrisPool.activeCount {
                                        neighborPos = debrisPosPtr[debrisIdx]
                                        neighborVel = debrisVelPtr[debrisIdx]
                                        isNeighborActive = true
                                    }
                                }
                                
                                if isNeighborActive {
                                    if abs(primaryPos.x - neighborPos.x) <= radius {
                                        if length_squared(primaryPos - neighborPos) < thresholdSq {
                                            collisionLock.lock()
                                            if primary.isEnabled {
                                                primary.isEnabled = false
                                                localConfirmed.append((primaryPos, primary.components[OrbitalData.self]?.velocity ?? .zero))
                                                if isNeighborSatellite {
                                                    if satellites[neighborIndex].isEnabled {
                                                        satellites[neighborIndex].isEnabled = false
                                                        localConfirmed.append((neighborPos, neighborVel))
                                                    }
                                                } else {
                                                    debrisPool.kill(at: neighborIndex - satCount)
                                                    localConfirmed.append((neighborPos, neighborVel))
                                                }
                                            }
                                            collisionLock.unlock()
                                        }
                                    }
                                }
                            }
                            neighborIndex = grid.nextObject(after: neighborIndex)
                        }
                    }
                }
                
                for (pos, vel) in localConfirmed {
                    spawnExplosion(at: pos, velocity: vel)
                }
            }
        }
    }
    
    func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        
        debrisPool.reset()
        grid.clear()
        
        let orbitAlt = Float(settings.orbitAltitude)
        let gravityMult = Float(settings.gravityMultiplier)
        
        for i in 0..<satelliteCount {
            let angle = (Float(i) / Float(satelliteCount)) * 2 * .pi
            let radius = orbitAlt + Float.random(in: -8.0...8.0)
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            
            let orbitalSpeed = sqrt((gravitationalConstant * earthMass * gravityMult) / radius)
            let velocityX = -sin(angle) * orbitalSpeed
            let velocityZ = cos(angle) * orbitalSpeed
            
            let orbitRotation: simd_quatf = settings.useRandomInclination
            ? simd_quatf(angle: Float.random(in: 0...(.pi*2)), axis: [1, 0, 0])
            : simd_quatf(angle: 0, axis: [1, 0, 0])
            
            let finalPosition = orbitRotation.act(SIMD3<Float>(x, 0, z))
            let finalVelocity = orbitRotation.act(SIMD3<Float>(velocityX, 0, velocityZ))
            
            let entity = ModelEntity(mesh: satelliteMesh, materials: [satelliteMaterial])
            let scale = Float(settings.satelliteScale)
            entity.scale = [scale, scale, scale]
            entity.position = finalPosition
            
            entity.components.set(OrbitalData(velocity: finalVelocity, radius: 0.5 * scale, type: .leo))
            
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
                self.settings = newSettings
                updateLighting()
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
    
    func rotateCamera(deltaX: Float, deltaY: Float) {
        cameraAngleX += deltaX
        cameraAngleY += deltaY
        cameraAngleX = max(-1.4, min(1.4, cameraAngleX))
        updateCameraTransform()
    }
    
    func zoomCamera(scaleFactor: Float) {
        cameraZoomLevel /= scaleFactor
        cameraZoomLevel = max(120, min(800, cameraZoomLevel))
        cameraEntity.position.z = cameraZoomLevel
    }
    
    func resetCamera() {
        let targetAngleX: Float = -0.35
        let targetAngleY: Float = 3.25
        let targetZoom: Float = 350.0
        
        self.cameraAngleX = targetAngleX
        self.cameraAngleY = targetAngleY
        self.cameraZoomLevel = targetZoom
        
        let rotationY = simd_quatf(angle: targetAngleY, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: targetAngleX, axis: [1, 0, 0])
        let targetOrientation = rotationY * rotationX
        
        let targetCameraTransform = Transform(scale: .one, rotation: .init(), translation: [0, 0, targetZoom])
        
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
        earthMaterial.roughness = .init(floatLiteral: 0.9)
        earthMaterial.metallic = .init(floatLiteral: 0.0)
        
        if let texture = try? TextureResource.load(named: "earthTopographicMap") {
            earthMaterial.baseColor = .init(texture: .init(texture))
        } else {
            earthMaterial.baseColor = .init(tint: .blue)
        }
        
        let earth = ModelEntity(mesh: earthMesh, materials: [earthMaterial])
        self.earthEntity = earth
        rootAnchor.addChild(earth)
        
        let atmosphereMesh = MeshResource.generateSphere(radius: earthRadius + 1.75)
        var atmosphereMaterial = PhysicallyBasedMaterial()
        atmosphereMaterial.baseColor = .init(tint: .blue.withAlphaComponent(0.1))
        atmosphereMaterial.roughness = .init(floatLiteral: 1.0)
        atmosphereMaterial.metallic = .init(floatLiteral: 0.0)
        atmosphereMaterial.blending = .transparent(opacity: 0.3)
        
        let atmosphere = ModelEntity(mesh: atmosphereMesh, materials: [atmosphereMaterial])
        earth.addChild(atmosphere)
    }
    
    func updateEarthRotation() {
        guard let earth = earthEntity else { return }
        let deltaTime = (1.0 / 60.0) * Float(settings.timeScale)
        let rotationSpeed: Float = 0.02
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
