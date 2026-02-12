//
//  PhysicsEngine.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import Foundation
import RealityKit
import Combine
import UIKit

struct SpatialGrid {
    private var headCell: [Int32]
    private var nextParticle: [Int32]
    
    let gridSize: Int = 100
    let cellCount: Int = 1_000_000
    let offset: Float = 500.0
    let cellSize: Float
    
    init(maxObjects: Int, cellSize: Float) {
        self.cellSize = cellSize
        self.headCell = Array(repeating: -1, count: cellCount)
        self.nextParticle = Array(repeating: -1, count: maxObjects)
    }
    
    mutating func clear() {
        headCell.withUnsafeMutableBufferPointer { buffer in
            buffer.initialize(repeating: -1)
        }
    }
    
    @inline(__always)
    func getCellIndex(for position: SIMD3<Float>) -> Int {
        let x = Int((position.x + offset) / cellSize)
        let y = Int((position.y + offset) / cellSize)
        let z = Int((position.z + offset) / cellSize)
        
        if x >= 0 && x < gridSize && y >= 0 && y < gridSize && z >= 0 && z < gridSize {
            return x + (y * gridSize) + (z * gridSize * gridSize)
        }
        return -1
    }
    
    mutating func add(objectIndex: Int, position: SIMD3<Float>) {
        let cellID = getCellIndex(for: position)
        guard cellID != -1 else { return }
        
        nextParticle[objectIndex] = headCell[cellID]
        headCell[cellID] = Int32(objectIndex)
    }
    
    @inline(__always)
    func firstObject(inCell cellIndex: Int) -> Int {
        if cellIndex >= 0 && cellIndex < cellCount {
            return Int(headCell[cellIndex])
        }
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
    
    var debris: [ModelEntity] = []
    var debrisVelocities: [SIMD3<Float>] = []
    
    private var allEntities: [ModelEntity] = []
    private var grid: SpatialGrid
    
    var settings = SimSettings()
    var frameCounter = 0
    
    var cameraZoomLevel: Float = 350.0
    var cameraAngleX: Float = -0.35
    var cameraAngleY: Float = 3.25
    
    var debrisMeshSmall: MeshResource
    var debrisMeshMedium: MeshResource
    var debrisMeshLarge: MeshResource
    var satelliteMesh: MeshResource
    
    var debrisMaterialDark, debrisMaterialLight, debrisMaterialWhite: UnlitMaterial
    var satelliteMaterial: PhysicallyBasedMaterial
    
    let earthRadius: Float = 100.0
    let gravitationalConstant: Float = 1.0
    let earthMass: Float = 50000
    
    let debrisRotationDelta = simd_quatf(angle: 0.05, axis: [1, 0, 0])
    
    private var sceneUpdateSubscription: Cancellable?
    
    init() {
        OrbitalData.registerComponent()
        self.grid = SpatialGrid(maxObjects: 15_000, cellSize: 10.0)
        
        debrisMaterialDark = UnlitMaterial(color: .gray)
        debrisMaterialLight = UnlitMaterial(color: .lightGray)
        debrisMaterialWhite = UnlitMaterial(color: .white)
        
        satelliteMaterial = PhysicallyBasedMaterial()
        satelliteMaterial.baseColor = .init(tint: .purple)
        satelliteMaterial.metallic = .init(floatLiteral: 0.6)
        satelliteMaterial.roughness = .init(floatLiteral: 0.4)
        
        satelliteMesh = .generateBox(size: 0.75)
        debrisMeshSmall = Self.generateDebrisPyramid(size: 0.35)
        debrisMeshMedium = Self.generateDebrisPyramid(size: 0.45)
        debrisMeshLarge = Self.generateDebrisPyramid(size: 0.55)
        
        debris.reserveCapacity(7000)
        debrisVelocities.reserveCapacity(7000)
        allEntities.reserveCapacity(8000)
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
        let debrisCount = min(Int(settings.debrisPerCollision), 20)
        let explosionImpulse = Float(settings.explosionForce) * 3.0
        
        let velocityDirection = normalize(velocity)
        let radialDirection = normalize(position)
        let normalDirection = normalize(cross(velocityDirection, radialDirection))
        
        let scaleTangential = Float(settings.spreadTangential) * 0.1
        let scaleVertical = Float(settings.spreadVertical) * 1.5
        let scaleRadial = Float(settings.spreadRadial) * 0.05
        
        for _ in 0...debrisCount {
            let randomTangential = Float.random(in: -1...1) * scaleTangential
            let randomVertical = Float.random(in: -1...1) * scaleVertical
            let randomRadial = Float.random(in: -1...1) * scaleRadial
            
            let impulseVector = (velocityDirection * randomTangential) +
            (normalDirection * randomVertical) +
            (radialDirection * randomRadial)
            
            let speedVariance = Float.random(in: 0.8...1.2)
            let finalVelocity = velocity + (impulseVector * explosionImpulse * speedVariance)
            let finalPosition = position + (impulseVector * 1.2)
            
            let roll = Float.random(in: 0...1)
            let mesh: MeshResource = roll < 0.5 ? debrisMeshSmall : (roll < 0.9 ? debrisMeshMedium : debrisMeshLarge)
            let material: UnlitMaterial = roll < 0.5 ? debrisMaterialDark : (roll < 0.9 ? debrisMaterialLight : debrisMaterialWhite)
            
            let debrisEntity = ModelEntity(mesh: mesh, materials: [material])
            let scale = Float(settings.debrisScale)
            debrisEntity.scale = [scale, scale, scale]
            debrisEntity.position = finalPosition
            debrisEntity.orientation = simd_quatf(angle: Float.random(in: 0...3), axis: [1, 1, 0])
            
            debrisEntity.components.set(OrbitalData(velocity: finalVelocity, radius: 1 * scale, type: .debris))
            
            rootAnchor.addChild(debrisEntity)
            
            debris.append(debrisEntity)
            debrisVelocities.append(finalVelocity)
        }
    }

    func runSimulationFrame() {
        if isPaused { return }
        
        processCommandQueue()
        
        updateSatellites()
        updateDebrisFast()
        updateEarthRotation()
        detectCollisions()
        
        frameCounter += 1
        if frameCounter % 15 == 0 { publishStats() }
    }
    
    func updateSatellites() {
        let gravityMult = Float(settings.gravityMultiplier)
        let deltaTime = (1.0 / 60.0) * Float(settings.timeScale)
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
            let effectiveGravity = gravitationalConstant * earthMass * gravityMult
            let gravityAcceleration = pos * (-effectiveGravity / (distSq * sqrt(distSq)))
            
            data.velocity += gravityAcceleration * deltaTime
            entity.position += data.velocity * deltaTime
            entity.components[OrbitalData.self] = data
        }
    }
    
    func updateDebrisFast() {
        let gravityMult = Float(settings.gravityMultiplier)
        let deltaTime = (1.0 / 60.0) * Float(settings.timeScale)
        let debScale = Float(settings.debrisScale)
        let killRadius = earthRadius + 2.0
        
        for i in (0..<debris.count).reversed() {
            let entity = debris[i]
            
            var velocity = debrisVelocities[i]
            let pos = entity.position
            
            if !entity.isEnabled || length(pos) < killRadius {
                entity.removeFromParent()
                debris.remove(at: i)
                debrisVelocities.remove(at: i)
                continue
            }
            
            if entity.scale.x != debScale { entity.scale = [debScale, debScale, debScale] }
            
            let distSq = length_squared(pos)
            let gravityFactor = -(gravitationalConstant * earthMass * gravityMult) / (distSq * sqrt(distSq))
            
            velocity += pos * gravityFactor * deltaTime
            let newPos = pos + velocity * deltaTime
            
            entity.position = newPos
            entity.orientation *= debrisRotationDelta
            
            debrisVelocities[i] = velocity
        }
        
        if debris.count > settings.maxDebris {
            let overflow = debris.count - settings.maxDebris
            for _ in 0..<overflow {
                debris.first?.removeFromParent()
                debris.removeFirst()
                debrisVelocities.removeFirst()
            }
        }
    }
    
    func detectCollisions() {
        allEntities.removeAll(keepingCapacity: true)
        allEntities.append(contentsOf: satellites)
        allEntities.append(contentsOf: debris)
        
        grid.clear()
        
        for i in 0..<allEntities.count {
            let entity = allEntities[i]
            if entity.isEnabled {
                grid.add(objectIndex: i, position: entity.position)
            }
        }
        
        var confirmedCollisions: [(position: SIMD3<Float>, velocity: SIMD3<Float>)] = []
        let thresholdSq = Float(settings.collisionRadius * settings.collisionRadius)
        
        let gs = grid.gridSize
        let gs2 = gs * gs
        let neighborOffsets = [0, 1, -1, gs, -gs, gs2, -gs2]
        
        let satCount = satellites.count
        
        for i in 0..<satCount {
            let primary = allEntities[i]
            guard primary.isEnabled else { continue }
            
            let cellID = grid.getCellIndex(for: primary.position)
            if cellID == -1 { continue }
            
            for offset in neighborOffsets {
                let targetCell = cellID + offset
                var neighborIndex = grid.firstObject(inCell: targetCell)
                
                while neighborIndex != -1 {
                    if i != neighborIndex {
                        let neighbor = allEntities[neighborIndex]
                        
                        let isNeighborSatellite = neighborIndex < satCount
                        let shouldCheck = !isNeighborSatellite || (isNeighborSatellite && primary.id > neighbor.id)
                        
                        if shouldCheck && neighbor.isEnabled {
                            if length_squared(primary.position - neighbor.position) < thresholdSq {
                                primary.isEnabled = false
                                neighbor.isEnabled = false
                                
                                let v1 = primary.components[OrbitalData.self]?.velocity ?? .zero
                                
                                var v2: SIMD3<Float> = .zero
                                if isNeighborSatellite {
                                    v2 = neighbor.components[OrbitalData.self]?.velocity ?? .zero
                                } else {
                                    let debrisIndex = neighborIndex - satCount
                                    if debrisIndex >= 0 && debrisIndex < debrisVelocities.count {
                                        v2 = debrisVelocities[debrisIndex]
                                    }
                                }
                                
                                confirmedCollisions.append((primary.position, v1))
                                confirmedCollisions.append((neighbor.position, v2))
                            }
                        }
                    }
                    neighborIndex = grid.nextObject(after: neighborIndex)
                }
            }
        }
        
        for (pos, vel) in confirmedCollisions {
            spawnExplosion(at: pos, velocity: vel)
        }
    }
    
    func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.removeFromParent() }
        debris.forEach { $0.removeFromParent() }
        satellites.removeAll()
        debris.removeAll()
        debrisVelocities.removeAll()
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
        let stats = SimStats(debris: debris.count, satellites: satellites.count)
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
