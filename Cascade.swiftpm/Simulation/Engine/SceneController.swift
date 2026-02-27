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
    private var earthEntity: Entity?
    private let mainSun = DirectionalLight()
    private var fillLights: [Entity] = []
    
    private var satellites: [ModelEntity] = []
    private var satelliteMaterial: PhysicallyBasedMaterial
    private var debrisMaterial: UnlitMaterial
    private let satelliteMesh: MeshResource
    private var debrisBatchSystem: DebrisBatchSystem
    private var atmEntity: ModelEntity?
    private var aoTexture: TextureResource?
    
    private var system: PhysicsSolver
    private var physicsTask: Task<Void, Never>? = nil
    
    private var settings = SimSettings.defaults
    private let earthRadius: Float = 100.0
    private let gravitationalConstant: Float = 1.0
    private let earthMass: Float = 50000
    
    private var frameCounter = 0
    private var lastFrameTime: TimeInterval = 0
    
    private var commandQueue: [EngineCommand] = []
    private var sceneUpdateSubscription: Cancellable?
    
    init() {
        OrbitalData.registerComponent()
        
        var satMat = PhysicallyBasedMaterial()
        satMat.baseColor = .init(tint: UIColor(settings.satelliteColor))
        satMat.metallic = 0.7
        satMat.roughness = 0.3
        self.satelliteMaterial = satMat
        
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
        guard !isPaused else { return }
        
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        let effectiveEarthMass = earthMass * Float(settings.gravityMultiplier)
        
        updateSatellites(dt: deltaTime, earthMass: effectiveEarthMass)
        updateEarthRotation()
        
        guard physicsTask == nil else { return }
        
        var satPos: [SIMD3<Float>] = []
        var satVel: [SIMD3<Float>] = []
        var satIdx: [Int] = []
        
        for (i, sat) in satellites.enumerated() where sat.isEnabled {
            satPos.append(sat.position)
            satVel.append(sat.components[OrbitalData.self]?.velocity ?? .zero)
            satIdx.append(i)
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
            posX: frame.posX, posY: frame.posY, posZ: frame.posZ,
            rotAngle: frame.rotAngle,
            rotAxisX: frame.rotAxisX, rotAxisY: frame.rotAxisY, rotAxisZ: frame.rotAxisZ,
            scale: Float(settings.debrisScale),
            spinEnabled: settings.debrisRotation
        )
        
        for index in frame.killedSatelliteIndices where index < satellites.count {
            satellites[index].isEnabled = false
        }
        
        frameCounter += 1
        if frameCounter % 30 == 0 {
            let activeSats = satellites.filter { $0.isEnabled }.count
            simulationStats = SimStats(debris: frame.count, satellites: activeSats)
        }
    }
    
    private func updateSatellites(dt: Float, earthMass: Float) {
        for entity in satellites where entity.isEnabled {
            guard var data = entity.components[OrbitalData.self] else { continue }
            let pos = entity.position
            let distSq = length_squared(pos)
            data.velocity   += pos * (-earthMass / (distSq * sqrt(distSq))) * dt
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }
    
    private func updateEarthRotation() {
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        earthEntity?.orientation *= simd_quatf(angle: 0.2 * deltaTime, axis: [0, 1, 0])
    }
    
    func queueCommand(_ command: EngineCommand) {
        commandQueue.append(command)
    }
    
    private func processCommandQueue() {
        let commands = commandQueue
        commandQueue.removeAll()
        for command in commands {
            switch command {
            case .reset(let count): resetUniverse(satelliteCount: count)
            case .detonate: triggerRandomExplosion()
            case .updateSettings(let newS): handleSettingsUpdate(newS)
            }
        }
    }
    
    private func resetUniverse(satelliteCount: Int) {
        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        
        Task { await system.reset() }
        debrisBatchSystem.update(
            activeCount: 0,
            posX: [], posY: [], posZ: [],
            rotAngle: [], rotAxisX: [], rotAxisY: [], rotAxisZ: [],
            scale: 1.0,
            spinEnabled: settings.debrisRotation
        )
        
        spawnSatellites(count: satelliteCount)
        cameraRig?.reset()
        
        simulationStats = SimStats(debris: 0, satellites: satellites.count)
    }
    
    private func spawnSatellites(count: Int) {
        let orbitAlt = Float(settings.orbitAltitude)
        let orbitVar = Float(settings.orbitVariance)
        let gravityMult = Float(settings.gravityMultiplier)
        let GM = gravitationalConstant * earthMass * gravityMult
        let scale = Float(settings.satelliteScale)
        
        let goldenAngle: Float = 2.399963229
        
        satellites.reserveCapacity(count)
        
        for i in 0..<count {
            let radius = orbitAlt + Float.random(in: -orbitVar...orbitVar)
            let orbitalSpeed = sqrt(GM / radius)
            
            let finalPos: SIMD3<Float>
            let finalVel: SIMD3<Float>
            
            if settings.useRandomInclination {
                let z = 1.0 - (2.0 * Float(i) + 1.0) / Float(count)
                let sinTheta = sqrt(max(0.0, 1.0 - z * z))
                let phi = goldenAngle * Float(i)
                
                let ux = sinTheta * cos(phi)
                let uy = z
                let uz = sinTheta * sin(phi)
                
                finalPos = SIMD3<Float>(ux, uy, uz) * radius
                
                let radial = SIMD3<Float>(ux, uy, uz)
                var randVec = SIMD3<Float>(
                    Float.random(in: -1...1),
                    Float.random(in: -1...1),
                    Float.random(in: -1...1)
                )
                randVec = randVec - radial * dot(randVec, radial)
                if length(randVec) < 0.001 {
                    randVec = abs(ux) < 0.9 ? cross(radial, SIMD3(1, 0, 0)) : cross(radial, SIMD3(0, 1, 0))
                }
                finalVel = normalize(randVec) * orbitalSpeed
                
            } else {
                let anomaly = (Float(i) / Float(count)) * 2.0 * .pi
                finalPos = SIMD3<Float>( cos(anomaly), 0,  sin(anomaly)) * radius
                finalVel = SIMD3<Float>(-sin(anomaly), 0,  cos(anomaly)) * orbitalSpeed
            }
            
            let entity = ModelEntity(mesh: satelliteMesh, materials: [satelliteMaterial])
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
    
    private func handleSettingsUpdate(_ newSettings: SimSettings) {
        let colorChanged = settings.satelliteColor != newSettings.satelliteColor ||
        settings.debrisColor != newSettings.debrisColor
        let visualsChanged = settings.satelliteScale != newSettings.satelliteScale ||
        settings.showSatellites != newSettings.showSatellites
        
        self.settings = newSettings
        
        updateLightingMode()
        if colorChanged   { updateMaterials() }
        if visualsChanged { updateSatelliteVisuals() }
        
        arView?.environment.background = .color(UIColor(settings.backgroundColor))
        earthEntity?.isEnabled = newSettings.showEarth
        debrisBatchSystem.entity.isEnabled = newSettings.showDebris
        
        Task { await system.updateSettings(newSettings) }
    }
    
    private func updateMaterials() {
        self.satelliteMaterial.baseColor = .init(tint: UIColor(settings.satelliteColor))
        self.debrisMaterial = UnlitMaterial(color: UIColor(settings.debrisColor))
        
        for sat in satellites {
            if var model = sat.model {
                model.materials = [satelliteMaterial]
                sat.model = model
            }
        }
        debrisBatchSystem.updateMaterial(debrisMaterial)
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
    
    private func updateLightingMode() {
        if settings.useOmniLight {
            mainSun.removeFromParent()
            cameraRig?.camera.addChild(mainSun)
            mainSun.transform = .identity
        } else {
            mainSun.removeFromParent()
            rootAnchor.addChild(mainSun)
            mainSun.look(at: [0, 0, 0], from: [500, 0, -500], relativeTo: nil)
        }
        
        fillLights.forEach { $0.removeFromParent() }
        fillLights.removeAll()
        
        if let earthModelEntity = earthEntity as? ModelEntity,
           var earthModel = earthModelEntity.model,
           var earthMat = earthModel.materials.first as? PhysicallyBasedMaterial {
            
            if settings.useOmniLight {
                earthMat.ambientOcclusion = PhysicallyBasedMaterial.AmbientOcclusion()
            } else if let tex = aoTexture {
                earthMat.ambientOcclusion = PhysicallyBasedMaterial.AmbientOcclusion(texture: MaterialParameters.Texture(tex))
            }
            
            earthModel.materials = [earthMat]
            earthModelEntity.model = earthModel
        }
    }
    
    private func setupLighting() {
        mainSun.light.intensity = 6500
        mainSun.look(at: [0, 0, 0], from: [500, 0, -500], relativeTo: nil)
        rootAnchor.addChild(mainSun)
    }
    
    private func setupEarth() {
        let earthMesh = MeshResource.generateSphere(radius: earthRadius)
        var earthMaterial = PhysicallyBasedMaterial()
        earthMaterial.roughness = 1.0
        earthMaterial.metallic = 0.0
        earthMaterial.specular = 0.5
        earthMaterial.baseColor = .init(tint: .systemBlue)
        
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
        
        let atmEntity = ModelEntity(mesh: atmMesh, materials: [atmMat])
        self.atmEntity = atmEntity
        earth.addChild(atmEntity)
        
        Task {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            let image = renderer.image { ctx in
                UIColor(white: 0.225, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            
            guard let cgImage = image.cgImage else { return }
            async let loadedAO = try? TextureResource(image: cgImage, options: .init(semantic: .raw))
            async let loadedEarth = try? TextureResource(named: "earthmap")
            self.aoTexture = await loadedAO
            
            if !self.settings.useOmniLight, let tex = self.aoTexture {
                earthMaterial.ambientOcclusion = .init(texture: .init(tex))
                atmMat.ambientOcclusion = .init(texture: .init(tex))
            }
            
            if let tex = await loadedEarth {
                earthMaterial.baseColor = .init(tint: .white, texture: .init(tex))
            }
            
            earth.model?.materials = [earthMaterial]
            atmEntity.model?.materials = [atmMat]
        }
    }
    
    func setPaused(_ paused: Bool) { self.isPaused = paused }
    func rotateCamera(deltaX: Float, deltaY: Float) { cameraRig?.rotate(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { cameraRig?.zoom(scaleFactor: scaleFactor) }
    func resetCamera() { cameraRig?.reset() }
    
    func setCameraOffset(ratio: Float, aspectRatio: Float) {
        Task { @MainActor [weak self] in
            self?.cameraRig?.setTargetOffset(ratio: ratio, aspectRatio: aspectRatio)
        }
    }
}
