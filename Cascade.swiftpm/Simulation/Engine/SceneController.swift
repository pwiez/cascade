import simd
import Combine
import UIKit
import RealityKit

@MainActor
class SceneController: ObservableObject {
    
    
    @Published var simulationStats = SimStats()
    var isPaused: Bool = true
    
    
    private weak var arView: ARView?
    private let rootAnchor = AnchorEntity(world: .zero)
    
    
    private var cameraRig: CameraRig?
    private var system: PhysicsSolver
    private var debrisBatchSystem: DebrisBatchSystem
    
    
    private var earthEntity: Entity?
    private let mainSun = DirectionalLight()
    private var fillLights: [Entity] = []
    private var satellites: [ModelEntity] = []
    
    
    private var satelliteMaterial: UnlitMaterial
    private var debrisMaterial: UnlitMaterial
    private let satelliteMesh: MeshResource
    
    
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
        OrbitalData.registerComponent()
        
        self.satelliteMaterial = UnlitMaterial(color: UIColor(settings.satelliteColor))
        self.debrisMaterial = UnlitMaterial(color: UIColor(settings.debrisColor))
        self.satelliteMesh = .generateBox(size: 1.2)
        
        self.debrisBatchSystem = DebrisBatchSystem(maxDebris: 5000, material: debrisMaterial)
        self.system = PhysicsSolver(settings: settings, earthRadius: earthRadius)
        
        setupLighting()
        setupEarth()
        
        rootAnchor.addChild(debrisBatchSystem.entity)
    }
    
    
    func attach(to view: ARView) {
        self.arView = view
        
        if cameraRig == nil {
            self.cameraRig = CameraRig(rootAnchor: rootAnchor)
        }
        
        if rootAnchor.parent == nil {
            view.scene.addAnchor(rootAnchor)
        }
        
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.runSimulationFrame()
        }
    }
    
    
    private func runSimulationFrame() {
        let currentTime = CACurrentMediaTime()
        if lastFrameTime == 0 { lastFrameTime = currentTime }
        if (currentTime - lastFrameTime) < 0.016 { return }
        lastFrameTime += 0.016
        
        processCommandQueue()
        
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
            rotAngle: frame.rotAngle,
            rotAxisX: frame.rotAxisX,
            rotAxisY: frame.rotAxisY,
            rotAxisZ: frame.rotAxisZ,
            scale: Float(settings.debrisScale)
        )
        
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
    
    
    private func updateSatellites(dt: Float, earthMass: Float) {
        for entity in satellites where entity.isEnabled {
            guard var data = entity.components[OrbitalData.self] else { continue }
            
            let pos = entity.position
            let distSq = length_squared(pos)
            let gravityAccel = pos * (-earthMass / (distSq * sqrt(distSq)))
            
            data.velocity += gravityAccel * dt
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }
    
    private func updateSatelliteVisuals() {
        let satScale = Float(settings.satelliteScale)
        let showModels = settings.showSatellites
        
        for entity in satellites {
            let hasModel = entity.components.has(ModelComponent.self)
            
            
            if showModels && !hasModel {
                entity.components.set(ModelComponent(mesh: satelliteMesh, materials: [satelliteMaterial]))
            } else if !showModels && hasModel {
                entity.components.remove(ModelComponent.self)
            }
            
            
            if entity.scale.x != satScale {
                entity.scale = SIMD3<Float>(repeating: satScale)
            }
        }
    }
    
    private func updateEarthRotation() {
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        earthEntity?.orientation *= simd_quatf(angle: 0.2 * deltaTime, axis: [0, 1, 0])
    }
    
    
    private func setupLighting() {
        mainSun.light.intensity = 6200
        mainSun.look(at: [0, 0, 0], from: [500, 0, -500], relativeTo: nil)
        rootAnchor.addChild(mainSun)
    }
    
    private func setupEarth() {
        let blackTex = createBlackTexture()
        
        
        let earthMesh = MeshResource.generateSphere(radius: earthRadius)
        var earthMaterial = PhysicallyBasedMaterial()
        
        earthMaterial.roughness = 1.0
        earthMaterial.metallic = 0.0
        earthMaterial.specular = 0.5
        
        if let tex = blackTex {
            earthMaterial.ambientOcclusion = .init(texture: .init(tex))
        }
        
        
        if let texture = try? TextureResource.load(named: "earthmap") {
            earthMaterial.baseColor = .init(tint: .white, texture: .init(texture))
        } else {
            earthMaterial.baseColor = .init(tint: .systemBlue)
        }
        
        let earth = ModelEntity(mesh: earthMesh, materials: [earthMaterial])
        earth.orientation = simd_quatf(angle: 23.5 * .pi / 180, axis: [0, 0, 1])
        self.earthEntity = earth
        rootAnchor.addChild(earth)
        
        
        let atmMesh = MeshResource.generateSphere(radius: earthRadius + 1.2)
        var atmMat = PhysicallyBasedMaterial()
        
        atmMat.baseColor = .init(tint: UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0))
        atmMat.roughness = 1.0
        atmMat.metallic = 0.0
        atmMat.specular = 0.5
        atmMat.blending = .transparent(opacity: 0.15)
        
        if let tex = blackTex {
            atmMat.ambientOcclusion = .init(texture: .init(tex))
        }
        
        let atmosphere = ModelEntity(mesh: atmMesh, materials: [atmMat])
        earth.addChild(atmosphere)
    }
    
    
    func queueCommand(_ command: EngineCommand) {
        commandQueue.append(command)
    }
    
    private func processCommandQueue() {
        let commands = commandQueue
        commandQueue.removeAll()
        for command in commands {
            switch command {
            case .reset(let count):
                resetUniverse(satelliteCount: count)
            case .detonate:
                triggerRandomExplosion()
            case .updateSettings(let newSettings):
                handleSettingsUpdate(newSettings)
            }
        }
    }
    
    
    private func handleSettingsUpdate(_ newSettings: SimSettings) {
        let colorChanged = (self.settings.satelliteColor != newSettings.satelliteColor) || (self.settings.debrisColor != newSettings.debrisColor)
        
        
        let visualsChanged = (self.settings.satelliteScale != newSettings.satelliteScale) || (self.settings.showSatellites != newSettings.showSatellites)
        
        self.settings = newSettings
        
        updateFillLight()
        
        if colorChanged {
            updateMaterials()
        }
        
        
        if visualsChanged {
            updateSatelliteVisuals()
        }
        
        let newBG = UIColor(settings.backgroundColor)
        arView?.environment.background = .color(newBG)
        
        Task { await system.updateSettings(newSettings) }
        
        earthEntity?.isEnabled = newSettings.showEarth
    }
    
    private func updateMaterials() {
        let satColor = UIColor(settings.satelliteColor)
        let debrisColor = UIColor(settings.debrisColor)
        
        self.satelliteMaterial = UnlitMaterial(color: satColor)
        self.debrisMaterial = UnlitMaterial(color: debrisColor)
        
        for sat in satellites {
            if var model = sat.model {
                model.materials = [satelliteMaterial]
                sat.model = model
            }
        }
        
        debrisBatchSystem.updateMaterial(debrisMaterial)
    }
    
    
    private func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        
        Task { await system.reset() }
        debrisBatchSystem.update(
            activeCount: 0,
            posX: [], posY: [], posZ: [],
            rotAngle: [], rotAxisX: [], rotAxisY: [], rotAxisZ: [],
            scale: 1.0
        )
        
        spawnSatellites(count: satelliteCount)
        cameraRig?.reset()
        
        simulationStats = SimStats(debris: 0, satellites: satellites.count)
    }
    
    private func spawnSatellites(count: Int) {
        let orbitAlt = Float(settings.orbitAltitude)
        let orbitVar = Float(settings.orbitVariance)
        let gravityMult = Float(settings.gravityMultiplier)
        var spawnedPositions: [SIMD3<Float>] = []
        spawnedPositions.reserveCapacity(count)
        
        for i in 0..<count {
            let indexFloat = Float(i)
            let totalFloat = Float(count)
            
            
            let anomaly = (indexFloat / totalFloat) * 2.0 * .pi
            
            
            let goldenAngle: Float = 2.399963
            let raan = settings.useRandomInclination ? indexFloat * goldenAngle : 0.0
            
            
            let inclination = settings.useRandomInclination ? acos(1.0 - 2.0 * (indexFloat / totalFloat)) : 0.0
            
            let radius = orbitAlt + Float.random(in: -orbitVar...orbitVar)
            
            let x = radius * cos(anomaly)
            let z = radius * sin(anomaly)
            
            let orbitalSpeed = sqrt((gravitationalConstant * earthMass * gravityMult) / radius)
            let vx = -sin(anomaly) * orbitalSpeed
            let vz = cos(anomaly) * orbitalSpeed
            
            let rotInclination = simd_quatf(angle: inclination, axis: [1, 0, 0])
            let rotRAAN = simd_quatf(angle: raan, axis: [0, 1, 0])
            let combinedRotation = rotRAAN * rotInclination
            
            let finalPos = combinedRotation.act(SIMD3<Float>(x, 0, z))
            let finalVel = combinedRotation.act(SIMD3<Float>(vx, 0, vz))
            
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
    }
    
    private func updateFillLight() {
        if settings.useOmniLight {
            if fillLights.isEmpty {
                
                
                let fillPositions: [SIMD3<Float>] = [
                    [-500,    0,  500], 
                    [-500,  300, -200], 
                    [ 200, -300,  500]  
                ]
                
                for pos in fillPositions {
                    let light = DirectionalLight()
                    
                    light.light.intensity = 3500
                    light.light.color = .init(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0)
                    
                    light.look(at: [0, 0, 0], from: pos, relativeTo: nil)
                    
                    rootAnchor.addChild(light)
                    fillLights.append(light)
                }
            }
        } else {
            fillLights.forEach { $0.removeFromParent() }
            fillLights.removeAll()
        }
    }
    
    func setPaused(_ paused: Bool) {
        self.isPaused = paused
    }
    
    func rotateCamera(deltaX: Float, deltaY: Float) { cameraRig?.rotate(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { cameraRig?.zoom(scaleFactor: scaleFactor) }
    func resetCamera() { cameraRig?.reset() }
    func setCameraOffset(ratio: Float, aspectRatio: Float) {
        Task { @MainActor [weak self] in
            guard let self = self, let rig = self.cameraRig else { return }
            rig.setTargetOffset(ratio: ratio, aspectRatio: aspectRatio)
        }
    }
    
    private func createBlackTexture() -> TextureResource? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        guard let cgImage = image.cgImage else { return nil }
        
        let options = TextureResource.CreateOptions(semantic: .raw)
        return try? TextureResource(image: cgImage, options: options)
    }
}
