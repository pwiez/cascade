import simd
import Combine
import UIKit
import RealityKit

@MainActor
class PhysicsEngine: ObservableObject {
    
    var onCinematicEvent: (() -> Void)?
    
    @Published var simulationStats = SimStats()
    var isPaused: Bool = false
    
    private weak var arView: ARView?
    private let rootAnchor: AnchorEntity
    
    private var cameraRig: CameraRig?
    private var system: PhysicsSystem
    private var debrisBatchSystem: DebrisBatchSystem
    
    private var cinematicLock = false
    private var cinematicCountdown: Int = -1
    private var pendingCinematicTarget: SIMD3<Float>?
    
    private var earthEntity: Entity?
    private let mainSun: DirectionalLight
    private var fillLight: DirectionalLight?
    private var satellites: [ModelEntity] = []
    
    private var satelliteMaterial: Material
    private let satelliteMesh: MeshResource
    private let standardSatMaterial = UnlitMaterial(color: .green)
    private let standardDebrisMaterial = UnlitMaterial(color: .white)
    private let highContrastSatMaterial = UnlitMaterial(color: .green)
    private let highContrastDebrisMaterial = UnlitMaterial(color: .red)
    
    private var settings = SimSettings.defaults
    private var frameCounter = 0
    private var lastFrameTime: TimeInterval = 0
    private var physicsTask: Task<Void, Never>? = nil
    private var commandQueue: [EngineCommand] = []
    private var sceneUpdateSubscription: Cancellable?
    
    private let earthRadius: Float = 100.0
    private let gravitationalConstant: Float = 1.0
    private let earthMass: Float = 50000
    
    init() {
        self.rootAnchor = AnchorEntity(world: .zero)
        self.mainSun = DirectionalLight()
        OrbitalData.registerComponent()
        
        self.satelliteMaterial = standardSatMaterial
        self.satelliteMesh = .generateBox(size: 1.2)
        
        self.debrisBatchSystem = DebrisBatchSystem(maxDebris: 5_500, material: standardDebrisMaterial)
        self.system = PhysicsSystem(settings: settings, earthRadius: earthRadius)
        
        setupLighting()
        setupEarth()
        
        rootAnchor.addChild(debrisBatchSystem.entity)
    }
    
    func attach(to view: ARView) {
        self.arView = view
        if cameraRig == nil { self.cameraRig = CameraRig(rootAnchor: rootAnchor) }
        if rootAnchor.parent == nil { view.scene.addAnchor(rootAnchor) }
        
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.runSimulationFrame()
        }
    }
    
    private func runSimulationFrame() {
        let currentTime = CACurrentMediaTime()
        if lastFrameTime == 0 { lastFrameTime = currentTime }
        if (currentTime - lastFrameTime) < 0.016 { return }
        lastFrameTime = currentTime
        
        processCommandQueue()
        
        if cinematicCountdown > 0 {
            cinematicCountdown -= 1
            if cinematicCountdown == 0 { executeCinematicFreeze() }
        }
        
        if isPaused { return }
        
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        let gravityMult = Float(settings.gravityMultiplier)
        let effectiveEarthMass = earthMass * gravityMult
        
        updateSatellites(dt: deltaTime, earthMass: effectiveEarthMass)
        updateEarthRotation()
        
        guard physicsTask == nil else { return }
        
        var satPos: [SIMD3<Float>] = []
        var satVel: [SIMD3<Float>] = []
        var satIdx: [Int] = []
        
        for (i, sat) in satellites.enumerated() {
            if sat.isEnabled {
                satPos.append(sat.position)
                satVel.append(sat.components[OrbitalData.self]?.velocity ?? .zero)
                satIdx.append(i)
            }
        }
        
        physicsTask = Task {
            let frame = await system.step(
                dt: deltaTime,
                earthMass: effectiveEarthMass,
                satellitePositions: satPos,
                satelliteVelocities: satVel,
                satelliteIndices: satIdx
            )
            
            self.applySimulationFrame(frame)
            self.physicsTask = nil
        }
    }
    
    private func applySimulationFrame(_ frame: SimulationFrame) {
        debrisBatchSystem.update(
            activeCount: frame.count,
            posX: frame.posX,
            posY: frame.posY,
            posZ: frame.posZ,
            scale: Float(settings.debrisScale)
        )
        
        if !frame.explosions.isEmpty {
            if !cinematicLock, let firstBoom = frame.explosions.first {
                triggerCinematicEvent(at: firstBoom.position)
            }
        }
        
        for index in frame.killedSatelliteIndices {
            if index < satellites.count {
                satellites[index].isEnabled = false
            }
        }
        
        frameCounter += 1
        if frameCounter % 30 == 0 {
            let activeSats = satellites.filter({ $0.isEnabled }).count
            simulationStats = SimStats(debris: frame.count, satellites: activeSats)
        }
    }
    
    private func scheduleCinematicFreeze(at position: SIMD3<Float>) {
        guard cinematicCountdown == -1 && !cinematicLock else { return }
        pendingCinematicTarget = position
        cinematicCountdown = 3
    }
    
    private func executeCinematicFreeze() {
        guard let target = pendingCinematicTarget else { return }
        cinematicLock = true
        self.isPaused = true
        
        cameraRig?.focusOn(position: target)
        
        onCinematicEvent?()
    }
    
    private func triggerCinematicEvent(at position: SIMD3<Float>) {
        guard !cinematicLock else { return }
        cinematicLock = true
        
        cameraRig?.focusOn(position: position)
        self.isPaused = true
        
        onCinematicEvent?()
    }
    
    private func updateSatellites(dt: Float, earthMass: Float) {
        let satScale = Float(settings.satelliteScale)
        let showModels = settings.showSatellites
        
        for entity in satellites where entity.isEnabled {
            guard var data = entity.components[OrbitalData.self] else { continue }
            
            let hasModel = entity.components.has(ModelComponent.self)
            if showModels && !hasModel {
                entity.components.set(ModelComponent(mesh: satelliteMesh, materials: [satelliteMaterial]))
            } else if !showModels && hasModel {
                entity.components.remove(ModelComponent.self)
            }
            
            if entity.scale.x != satScale { entity.scale = SIMD3<Float>(repeating: satScale) }
            
            let pos = entity.position
            let distSq = length_squared(pos)
            let gravityAccel = pos * (-earthMass / (distSq * sqrt(distSq)))
            
            data.velocity += gravityAccel * dt
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }
    
    private func updateEarthRotation() {
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        earthEntity?.orientation *= simd_quatf(angle: 0.2 * deltaTime, axis: [0, 1, 0])
    }
    
    private func setupLighting() {
        mainSun.light.intensity = 5000
        mainSun.look(at: [0,0,0], from: [0, 50, -500], relativeTo: nil)
        rootAnchor.addChild(mainSun)
    }
    
    private func setupEarth() {
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
    
    func queueCommand(_ command: EngineCommand) { commandQueue.append(command) }
    
    private func processCommandQueue() {
        let commands = commandQueue
        commandQueue.removeAll()
        for command in commands {
            switch command {
            case .reset(let count): resetUniverse(satelliteCount: count)
            case .detonate: triggerRandomExplosion()
            case .updateSettings(let newSettings): handleSettingsUpdate(newSettings)
            }
        }
    }
    
    private func handleSettingsUpdate(_ newSettings: SimSettings) {
        let contrastChanged = (self.settings.highContrast != newSettings.highContrast)
        self.settings = newSettings
        updateFillLight()
        if contrastChanged { updateHighContrastMode() }
        Task { await system.updateSettings(newSettings) }
        earthEntity?.isEnabled = newSettings.showEarth
    }
    
    private func resetUniverse(satelliteCount: Int) {
        cinematicLock = false
        cinematicCountdown = -1
        pendingCinematicTarget = nil
        
        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        
        Task { await system.reset() }
        debrisBatchSystem.update(activeCount: 0, posX: [], posY: [], posZ: [], scale: 1.0)
        
        spawnSatellites(count: satelliteCount)
        cameraRig?.reset()
    }
    
    func setPaused(_ paused: Bool) {
        if isPaused == true && paused == false {
            if cinematicLock {
                cameraRig?.restoreState()
                cinematicLock = false
                cinematicCountdown = -1
            }
        }
        self.isPaused = paused
    }
    
    private func spawnSatellites(count: Int) {
        let orbitAlt = Float(settings.orbitAltitude)
        let gravityMult = Float(settings.gravityMultiplier)
        var spawnedPositions: [SIMD3<Float>] = []
        spawnedPositions.reserveCapacity(count)
        
        for _ in 0..<count {
            var validPosition = false
            var attempts = 0
            var finalPos: SIMD3<Float> = .zero
            var finalVel: SIMD3<Float> = .zero
            
            while !validPosition && attempts < 10 {
                attempts += 1
                let anomaly = Float.random(in: 0...(2 * .pi))
                let raan = Float.random(in: 0...(2 * .pi))
                let inclination = settings.useRandomInclination ? Float.random(in: 0...(.pi)) : 0
                
                let radius = orbitAlt + Float.random(in: -12.0...12.0)
                
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
    
    private func triggerRandomExplosion() {
        guard let victim = satellites.filter({ $0.isEnabled }).randomElement(),
              let data = victim.components[OrbitalData.self] else { return }
        
        victim.isEnabled = false
        
        Task { await system.spawnExplosion(at: victim.position, velocity: data.velocity) }
        scheduleCinematicFreeze(at: victim.position)
    }
    
    private func updateHighContrastMode() {
        let isHighContrast = settings.highContrast
        let activeSatMat = isHighContrast ? highContrastSatMaterial : standardSatMaterial
        let activeDebrisMat = isHighContrast ? highContrastDebrisMaterial : standardDebrisMaterial
        
        self.satelliteMaterial = activeSatMat
        for sat in satellites {
            if var model = sat.model {
                model.materials = [activeSatMat]
                sat.model = model
            }
        }
        debrisBatchSystem.entity.model?.materials = [activeDebrisMat]
    }
    
    private func updateFillLight() {
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
    
    func rotateCamera(deltaX: Float, deltaY: Float) { cameraRig?.rotate(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { cameraRig?.zoom(scaleFactor: scaleFactor) }
    func setSidePanelOpen(_ isOpen: Bool) { cameraRig?.setSidePanelOpen(isOpen: isOpen) }
    func resetCamera() { cameraRig?.reset() }
}
