import Foundation
import RealityKit
import Combine
import UIKit

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
    
    var satellites: [PhysicsBody] = []
    var debris: [PhysicsBody] = []
    var settings = SimSettings()
    var frameCounter = 0
    
    private var collisionGrid: [Int: [PhysicsBody]] = [:]
    private let gridCellSize: Float = 10.0
    
    var cameraZoomLevel: Float = 350.0
    var cameraAngleX: Float = -0.35
    var cameraAngleY: Float = 3.25
    
    var debrisMeshSmall: MeshResource
    var debrisMeshMedium: MeshResource
    var debrisMeshLarge: MeshResource
    var satelliteMesh: MeshResource
    
    var debrisMaterialDark, debrisMaterialLight, debrisMaterialWhite: PhysicallyBasedMaterial
    var satelliteMaterial: PhysicallyBasedMaterial
    
    let earthRadius: Float = 100.0
    let gravitationalConstant: Float = 1.0
    let earthMass: Float = 50000
    let lowEarthOrbitAltitude: Float = 120.0
    
    private var sceneUpdateSubscription: Cancellable?
    
    init() {
        debrisMaterialDark = PhysicallyBasedMaterial()
        debrisMaterialDark.baseColor = .init(tint: .gray)
        debrisMaterialDark.roughness = .init(floatLiteral: 0.8)
        
        debrisMaterialLight = PhysicallyBasedMaterial()
        debrisMaterialLight.baseColor = .init(tint: .lightGray)
        debrisMaterialLight.roughness = .init(floatLiteral: 0.8)
        
        debrisMaterialWhite = PhysicallyBasedMaterial()
        debrisMaterialWhite.baseColor = .init(tint: .white)
        debrisMaterialWhite.roughness = .init(floatLiteral: 0.8)
        
        satelliteMaterial = PhysicallyBasedMaterial()
        satelliteMaterial.baseColor = .init(tint: .purple)
        satelliteMaterial.metallic = .init(floatLiteral: 0.6)
        satelliteMaterial.roughness = .init(floatLiteral: 0.4)
        
        satelliteMesh = .generateBox(size: 0.75)
        debrisMeshSmall = Self.generateDebrisPyramid(size: 0.35)
        debrisMeshMedium = Self.generateDebrisPyramid(size: 0.45)
        debrisMeshLarge = Self.generateDebrisPyramid(size: 0.55)
        
        collisionGrid.reserveCapacity(2000)
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
            let material: PhysicallyBasedMaterial = roll < 0.5 ? debrisMaterialDark : (roll < 0.9 ? debrisMaterialLight : debrisMaterialWhite)
            
            let debrisEntity = ModelEntity(mesh: mesh, materials: [material])
            
            let scale = Float(settings.debrisScale)
            debrisEntity.scale = [scale, scale, scale]
            
            debrisEntity.position = finalPosition
            debrisEntity.orientation = simd_quatf(angle: Float.random(in: 0...3), axis: [1, 1, 0])
            
            rootAnchor.addChild(debrisEntity)
            
            let newDebris = PhysicsBody(entity: debrisEntity,
                                        pos: finalPosition,
                                        vel: finalVelocity,
                                        radius: 1 * scale,
                                        type: .debris)
            debris.append(newDebris)
        }
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
    
    func runSimulationFrame() {
        if isPaused { return }
        
        processCommandQueue()
        updateSatellites()
        updateDebris()
        updateEarthRotation()
        detectCollisions()
        
        frameCounter += 1
        if frameCounter % 15 == 0 { publishStats() }
    }
    
    func processCommandQueue() {
        threadLock.lock()
        let commands = commandQueue
        commandQueue.removeAll()
        threadLock.unlock()
        
        for command in commands {
            switch command {
            case .reset(let count):
                resetUniverse(satelliteCount: count)
            case .detonate:
                triggerRandomExplosion()
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
    
    func detectCollisions() {
        collisionGrid.removeAll(keepingCapacity: true)
        
        func addBodyToGrid(_ body: PhysicsBody) {
            guard body.entity.isEnabled else { return }
            let gridX = Int((body.position.x / gridCellSize) + 50)
            let gridY = Int((body.position.y / gridCellSize) + 50)
            let gridZ = Int((body.position.z / gridCellSize) + 50)
            
            if gridX >= 0 && gridX < 100 && gridY >= 0 && gridY < 100 && gridZ >= 0 && gridZ < 100 {
                let cellKey = gridX | (gridY << 10) | (gridZ << 20)
                collisionGrid[cellKey, default: []].append(body)
            }
        }
        
        for sat in satellites { addBodyToGrid(sat) }
        for shard in debris { addBodyToGrid(shard) }
        
        var confirmedCollisions: [(position: SIMD3<Float>, velocity: SIMD3<Float>)] = []
        let thresholdSquared = Float(settings.collisionRadius * settings.collisionRadius)
        let neighborOffsets = [0, 1, -1, 1024, -1024, 1048576, -1048576]
        
        for primaryBody in satellites {
            guard primaryBody.entity.isEnabled else { continue }
            let gridX = Int((primaryBody.position.x / gridCellSize) + 50)
            let gridY = Int((primaryBody.position.y / gridCellSize) + 50)
            let gridZ = Int((primaryBody.position.z / gridCellSize) + 50)
            
            if gridX < 0 || gridX >= 100 || gridY < 0 || gridY >= 100 || gridZ < 0 || gridZ >= 100 { continue }
            let centerKey = gridX | (gridY << 10) | (gridZ << 20)
            
            for offset in neighborOffsets {
                let checkKey = centerKey + offset
                guard let cellContents = collisionGrid[checkKey] else { continue }
                
                for neighborBody in cellContents {
                    if primaryBody === neighborBody || !neighborBody.entity.isEnabled { continue }
                    if !neighborBody.isDebris && primaryBody.id > neighborBody.id { continue }
                    
                    if length_squared(primaryBody.position - neighborBody.position) < thresholdSquared {
                        primaryBody.entity.isEnabled = false
                        neighborBody.entity.isEnabled = false
                        confirmedCollisions.append((primaryBody.position, primaryBody.velocity))
                        confirmedCollisions.append((neighborBody.position, neighborBody.velocity))
                    }
                }
            }
        }
        
        for (pos, vel) in confirmedCollisions {
            spawnExplosion(at: pos, velocity: vel)
        }
    }
    
    func triggerRandomExplosion() {
        if let victim = satellites.filter({ $0.type == .leo }).randomElement() {
            victim.entity.isEnabled = false
            spawnExplosion(at: victim.position, velocity: victim.velocity)
        }
    }
    
    func updateSatellites() {
        let shouldRenderSatellites = settings.showSatellites
        let targetScale = SIMD3<Float>(repeating: Float(settings.satelliteScale))
        
        for i in (0..<satellites.count).reversed() {
            let body = satellites[i]
            
            if !body.entity.isEnabled {
                body.entity.removeFromParent()
                satellites.remove(at: i)
                continue
            }
            
            let hasModel = body.entity.components.has(ModelComponent.self)
            if shouldRenderSatellites && !hasModel {
                body.entity.components.set(ModelComponent(mesh: satelliteMesh, materials: [satelliteMaterial]))
            } else if !shouldRenderSatellites && hasModel {
                body.entity.components.remove(ModelComponent.self)
            }
            
            if body.entity.scale != targetScale {
                body.entity.scale = targetScale
            }
            
            applyOrbitalPhysics(to: body)
            
            if length(body.position) < (earthRadius + 2.0) {
                body.entity.removeFromParent()
                satellites.remove(at: i)
            }
        }
    }
    
    func updateDebris() {
        let maxDebris = settings.maxDebris
        let targetScale = SIMD3<Float>(repeating: Float(settings.debrisScale))
        
        if debris.count > maxDebris {
            let overflow = debris.count - maxDebris
            for _ in 0..<overflow {
                debris.first?.entity.removeFromParent()
                debris.removeFirst()
            }
        }
        
        for i in (0..<debris.count).reversed() {
            let body = debris[i]
            
            if length(body.position) < (earthRadius + 2.0) {
                body.entity.removeFromParent()
                debris.remove(at: i)
                continue
            }
            
            if body.entity.scale != targetScale {
                body.entity.scale = targetScale
            }
            
            applyOrbitalPhysics(to: body)
        }
    }
    
    private func applyOrbitalPhysics(to body: PhysicsBody) {
        let deltaTime = (1.0 / 60.0) * Float(settings.timeScale)
        let distSq = length_squared(body.position)
        let invDist = 1.0 / sqrt(distSq)
        
        let effectiveGravity = gravitationalConstant * earthMass * Float(settings.gravityMultiplier)
        let gravityAcceleration = body.position * (-effectiveGravity / distSq) * invDist
        
        body.velocity += gravityAcceleration * deltaTime
        body.position += body.velocity * deltaTime
        body.entity.position = body.position
        
        if body.isDebris {
            body.entity.orientation *= simd_quatf(angle: 0.05, axis: [1,0,0])
        }
    }
    
    func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.entity.removeFromParent() }
        debris.forEach { $0.entity.removeFromParent() }
        satellites.removeAll()
        debris.removeAll()
        collisionGrid.removeAll(keepingCapacity: true)
        
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
            
            let orbitRotation: simd_quatf
            if settings.useRandomInclination {
                orbitRotation = simd_quatf(angle: Float.random(in: 0...(.pi*2)), axis: [1, 0, 0])
            } else {
                orbitRotation = simd_quatf(angle: 0, axis: [1, 0, 0])
            }
            
            let finalPosition = orbitRotation.act(SIMD3<Float>(x, 0, z))
            let finalVelocity = orbitRotation.act(SIMD3<Float>(velocityX, 0, velocityZ))
            
            let entity = ModelEntity(mesh: satelliteMesh, materials: [satelliteMaterial])
            let scale = Float(settings.satelliteScale)
            entity.scale = [scale, scale, scale]
            entity.position = finalPosition
            rootAnchor.addChild(entity)
            
            satellites.append(PhysicsBody(entity: entity, pos: finalPosition, vel: finalVelocity, radius: 0.5 * scale, type: .leo))
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
        cameraAngleX = -0.35
        cameraAngleY = 3.25
        cameraZoomLevel = 350.0
        updateCameraTransform()
        cameraEntity.position.z = cameraZoomLevel
    }
    
    private func updateCameraTransform() {
        let rotationY = simd_quatf(angle: cameraAngleY, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: cameraAngleX, axis: [1, 0, 0])
        cameraPivot.orientation = rotationY * rotationX
    }
}
