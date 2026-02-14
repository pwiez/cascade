import simd
import Combine
import UIKit
import RealityKit

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
    private let standardDebrisMaterial = UnlitMaterial(color: .lightGray)
    private let highContrastSatMaterial = UnlitMaterial(color: .yellow)
    private let highContrastDebrisMaterial = UnlitMaterial(color: .red)
    
    var satelliteMaterial: Material
    var satelliteMesh: MeshResource
    
    var satellites: [ModelEntity] = []
    
    var debrisPool: DebrisPool!
    var debrisBatchSystem: DebrisBatchSystem!
    
    private var grid: SpatialGrid
    private var satPosCache: [SIMD3<Float>] = []
    private var satVelCache: [SIMD3<Float>] = []
    
    struct CollisionEvent {
        let position: SIMD3<Float>
        let velocity: SIMD3<Float>
    }
    
    var settings = SimSettings.defaults
    var frameCounter = 0
    var cameraZoomLevel: Float = 350.0
    var cameraAngleX: Float = -0.35
    var cameraAngleY: Float = 3.25
    private var isSettingsOpen: Bool = false
    let earthRadius: Float = 100.0
    let gravitationalConstant: Float = 1.0
    let earthMass: Float = 50000
    let debrisRotationDelta = simd_quatf(angle: 0.05, axis: [1, 0, 0])
    var killRadiusSq: Float
    let maxRadiusSq: Float = 250.0 * 250.0
    private var sceneUpdateSubscription: Cancellable?
    
    init() {
        OrbitalData.registerComponent()
        self.grid = SpatialGrid(maxObjects: 5_500, cellSize: 10.0)
        self.killRadiusSq = pow(earthRadius + 2.0, 2)
        
        self.satelliteMaterial = standardSatMaterial
        self.satelliteMesh = .generateBox(size: 1.2)
        
        self.debrisPool = DebrisPool(capacity: 5_000)
        
        self.debrisBatchSystem = DebrisBatchSystem(maxDebris: 5_000, material: standardDebrisMaterial)
    }
    
    func runSimulationFrame() {
        processCommandQueue()
        if isPaused { return }
        
        let gravityMult = Float(settings.gravityMultiplier)
        let deltaTime = (1.0 / 600.0) * Float(settings.timeScale)
        let earthMassVal = earthMass * gravityMult
        
        updateSatellites(dt: deltaTime, earthMass: earthMassVal)
        updateDebris(dt: deltaTime, earthMass: earthMassVal)
        updateEarthRotation()
        
        if frameCounter % 10 == 0 {
            detectCollisions()
        }
        
        frameCounter += 1
        if frameCounter % 60 == 0 { publishStats() }
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
            let gravityAccel = pos * (-earthMass / (distSq * sqrt(distSq)))
            
            data.velocity += gravityAccel * dt
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }
    
    func updateDebris(dt: Float, earthMass: Float) {
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
            
            debrisBatchSystem.update(
                activeCount: debrisPool.activeCount,
                posX: debrisPool.posX,
                posY: debrisPool.posY,
                posZ: debrisPool.posZ,
                scale: Float(settings.debrisScale)
            )
        }
    
    func detectCollisions() {
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
        
        for i in 0..<debrisPool.activeCount {
            let pos = debrisPool.position(at: i)
            grid.add(objectIndex: satPosCache.count + i, position: pos)
        }
        
        let radius = Float(settings.collisionRadius)
        let radiusSq = radius * radius
        let cacheCount = satPosCache.count
        
        class ThreadResult {
            var explosions: [CollisionEvent] = []
            var deaths: [Int] = []
            var debrisKills: [Int] = []
        }
        
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let buckets = (0..<coreCount).map { _ in ThreadResult() }
        
        let dPosX = debrisPool.posX
        let dPosY = debrisPool.posY
        let dPosZ = debrisPool.posZ
        let dVelX = debrisPool.velX
        let dVelY = debrisPool.velY
        let dVelZ = debrisPool.velZ
        let dActive = debrisPool.activeCount
        
        DispatchQueue.concurrentPerform(iterations: coreCount) { coreIndex in
            let stepSize = coreCount
            var localExplosions: [CollisionEvent] = []
            var localDeaths: [Int] = []
            var localDebrisKills: [Int] = []
            
            for i in stride(from: coreIndex, to: cacheCount, by: stepSize) {
                let posA = satPosCache[i]
                let cellID = grid.getCellIndex(for: posA)
                if cellID == -1 { continue }
                
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
                                if dIdx < dActive {
                                    posB = SIMD3(dPosX[dIdx], dPosY[dIdx], dPosZ[dIdx])
                                    velB = SIMD3(dVelX[dIdx], dVelY[dIdx], dVelZ[dIdx])
                                    isDebris = true
                                } else {
                                    neighborIdx = grid.nextObject(after: neighborIdx)
                                    continue
                                }
                            }
                            
                            if abs(posA.x - posB.x) <= radius &&
                               abs(posA.y - posB.y) <= radius &&
                               abs(posA.z - posB.z) <= radius {
                                
                                if length_squared(posA - posB) < radiusSq {
                                    localDeaths.append(activeSatIndices[i])
                                    localExplosions.append(CollisionEvent(position: posA, velocity: satVelCache[i]))
                                    
                                    if isDebris {
                                        localDebrisKills.append(neighborIdx - cacheCount)
                                        localExplosions.append(CollisionEvent(position: posB, velocity: velB))
                                    } else {
                                        localDeaths.append(activeSatIndices[neighborIdx])
                                        localExplosions.append(CollisionEvent(position: posB, velocity: velB))
                                    }
                                }
                            }
                        }
                        neighborIdx = grid.nextObject(after: neighborIdx)
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
        
        for satIndex in finalDeaths {
            if satIndex < satellites.count { satellites[satIndex].isEnabled = false }
        }
        for debrisIndex in Set(finalDebrisKills).sorted(by: >) {
            debrisPool.kill(at: debrisIndex)
        }
        for boom in finalExplosions {
            spawnExplosion(at: boom.position, velocity: boom.velocity)
        }
    }
    
    private func spawnExplosion(at position: SIMD3<Float>, velocity: SIMD3<Float>) {
        if debrisPool.activeCount >= settings.maxDebris { return }
        
        let debrisCount = min(Int(settings.debrisPerCollision), 20)
        let explosionImpulse = Float(settings.explosionForce) * 3.0
        
        let velocityDirection = normalize(velocity)
        let safePos = length(position) > 0.001 ? position : SIMD3<Float>(0, 1, 0)
        let radialDirection = normalize(safePos)
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
                            velocity: finalVelocity
                        )
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
                self.settings = newSettings
                
                updateLighting()
                if contrastChanged { updateHighContrastMode() }
                
                if contrastChanged {
                    let mat = newSettings.highContrast ? highContrastDebrisMaterial : standardDebrisMaterial
                    debrisBatchSystem.entity.model?.materials = [mat]
                }
                earthEntity?.isEnabled = newSettings.showEarth
            }
        }
    }
    
    func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        debrisPool.reset()
        grid.clear()
        
        debrisBatchSystem.update(activeCount: 0, posX: [], posY: [], posZ: [], scale: 1.0)
        
        let orbitAlt = Float(settings.orbitAltitude)
        let gravityMult = Float(settings.gravityMultiplier)
        
        var spawnedPositions: [SIMD3<Float>] = []
        spawnedPositions.reserveCapacity(satelliteCount)
        
        for _ in 0..<satelliteCount {
            var validPosition = false
            var attempts = 0
            var finalPos: SIMD3<Float> = .zero
            var finalVel: SIMD3<Float> = .zero
            
            while !validPosition && attempts < 10 {
                attempts += 1
                let anomaly = Float.random(in: 0...(2 * .pi))
                let raan = Float.random(in: 0...(2 * .pi))
                let inclination = settings.useRandomInclination ? Float.random(in: 0...(.pi)) : 0
                
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
                    if distance(existing, candidatePos) < 2.5 {
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
            entity.scale = SIMD3<Float>(repeating: scale)
            entity.position = finalPos
            entity.components.set(OrbitalData(velocity: finalVel, radius: 0.5 * scale, type: .leo))
            
            rootAnchor.addChild(entity)
            satellites.append(entity)
        }
    }
    
    func updateHighContrastMode() {
        guard let arView = arView else { return }
        let isHighContrast = settings.highContrast
        
        DispatchQueue.main.async {
            arView.environment.background = .color(.black)
        }
        
        let activeSatMat = isHighContrast ? highContrastSatMaterial : standardSatMaterial
        self.satelliteMaterial = activeSatMat
        
        for sat in satellites {
            if var model = sat.model {
                model.materials = [activeSatMat]
                sat.model = model
            }
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
            
            rootAnchor.addChild(debrisBatchSystem.entity)
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
            fillLight?.removeFromParent()
            fillLight = nil
        }
    }
    
    func setupEarth() {
        let earthMesh = MeshResource.generateSphere(radius: earthRadius)
        var earthMaterial = PhysicallyBasedMaterial()
        earthMaterial.roughness = 0.8
        earthMaterial.specular = 0.1
        
        if let texture = try? TextureResource.load(named: "earthTopographicMap") {
            earthMaterial.baseColor = .init(texture: .init(texture))
        } else {
            earthMaterial.baseColor = .init(tint: .systemBlue)
        }
        
        let earth = ModelEntity(mesh: earthMesh, materials: [earthMaterial])
        earth.orientation = simd_quatf(angle: 23.5 * .pi / 180, axis: [0, 0, 1])
        self.earthEntity = earth
        rootAnchor.addChild(earth)
        
        let atmMesh = MeshResource.generateSphere(radius: earthRadius + 2.0)
        var atmMat = PhysicallyBasedMaterial()
        atmMat.baseColor = .init(tint: UIColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.3))
        atmMat.roughness = 1.0
        atmMat.blending = .transparent(opacity: 0.25)
        
        let atmosphere = ModelEntity(mesh: atmMesh, materials: [atmMat])
        atmosphere.components.set(OpacityComponent(opacity: 0.5))
        earth.addChild(atmosphere)
    }
    
    func updateEarthRotation() {
        let deltaTime = (1.0 / 600.0) * Float(settings.timeScale)
        earthEntity?.orientation *= simd_quatf(angle: 0.2 * deltaTime, axis: [0, 1, 0])
    }
    
    func setupCamera() {
        cameraEntity.components.set(PerspectiveCameraComponent(near: 0.1, far: 3000))
        rootAnchor.addChild(cameraPivot)
        cameraPivot.addChild(cameraEntity)
        updateCameraTransform()
        cameraEntity.position.z = cameraZoomLevel
    }
    
    func triggerRandomExplosion() {
        if let victim = satellites.filter({ $0.isEnabled }).randomElement(),
           let data = victim.components[OrbitalData.self] {
            victim.isEnabled = false
            spawnExplosion(at: victim.position, velocity: data.velocity)
        }
    }
    
    func queueCommand(_ command: EngineCommand) {
        threadLock.lock()
        commandQueue.append(command)
        threadLock.unlock()
    }
    
    func publishStats() {
        if abs(simulationStats.debris - debrisPool.activeCount) < 5 &&
            abs(simulationStats.satellites - satellites.count) == 0 {
            return
        }
        let stats = SimStats(debris: debrisPool.activeCount, satellites: satellites.count)
        Task { self.simulationStats = stats }
    }
    
    func rotateCamera(deltaX: Float, deltaY: Float) {
        cameraAngleX = max(-1.4, min(1.4, cameraAngleX + deltaX))
        cameraAngleY += deltaY
        updateCameraTransform()
    }
    
    func zoomCamera(scaleFactor: Float) {
        cameraZoomLevel = max(120, min(800, cameraZoomLevel / scaleFactor))
        updateCameraPosition(animated: false)
    }
    
    func setSidePanelOpen(_ isOpen: Bool) {
        self.isSettingsOpen = isOpen
        updateCameraPosition(animated: true)
    }
    
    private func updateCameraPosition(animated: Bool) {
        let targetX = isSettingsOpen ? (cameraZoomLevel * 0.20) : 0.0
        let targetTransform = Transform(scale: .one, rotation: .init(), translation: SIMD3<Float>(targetX, 0, cameraZoomLevel))
        
        if animated {
            cameraEntity.move(to: targetTransform, relativeTo: cameraPivot, duration: 0.4, timingFunction: .easeInOut)
        } else {
            cameraEntity.transform = targetTransform
        }
    }
    
    func resetCamera() {
        self.cameraAngleX = -0.35
        self.cameraAngleY = 3.25
        self.cameraZoomLevel = 350.0
        updateCameraPosition(animated: true)
        
        let targetOrientation = simd_quatf(angle: cameraAngleY, axis: [0, 1, 0]) * simd_quatf(angle: cameraAngleX, axis: [1, 0, 0])
        cameraPivot.move(to: Transform(rotation: targetOrientation), relativeTo: rootAnchor, duration: 1.5, timingFunction: .easeInOut)
    }
    
    private func updateCameraTransform() {
        let rotationY = simd_quatf(angle: cameraAngleY, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: cameraAngleX, axis: [1, 0, 0])
        cameraPivot.orientation = rotationY * rotationX
    }
}
