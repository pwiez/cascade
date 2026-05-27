//
//  SceneController.swift
//  Cascade
//
//  Created by Pedro Wiezel on 09/02/26.
//

import simd
import Combine
import UIKit
import RealityKit

@MainActor
class SceneController: ObservableObject {
    
    
    @Published var simulationStats = SimStats()
    private var settings = SimSettings.defaults
    var isPaused: Bool = true
    
    private var system: PhysicsSolver
    private var physicsTask: Task<Void, Never>? = nil
    private var frameCounter = 0
    private var lastFrameTime: TimeInterval = 0
    
    private var pendingResetCount: Int? = nil
    private var pendingDetonate: Bool = false
    private var pendingSettings: SimSettings? = nil

    private weak var arView: ARView?
    private var sceneUpdateSubscription: Cancellable?
    private var cameraRig: CameraRig?
    private let rootAnchor = AnchorEntity(world: .zero)

    private let mainSun = DirectionalLight()
    private var fillLights: [Entity] = []
    
    private var satellites: [ModelEntity] = []
    private var satelliteMaterial: UnlitMaterial
    private let satelliteMesh: MeshResource
    private var debrisBatchSystem: DebrisBatchSystem

    private var earthEntity: Entity?
    private var earthSpinRate: Float = 0
    private let earthRadius: Float = 240.0
    private let earthMass: Float = 150_000
    private let gravitationalConstant: Float = 1.0
    private var atmEntity: ModelEntity?
    private var aoTexture: TextureResource?
    
    private var activeSatelliteCount: Int = 0
    private var satPosBuffer: [SIMD3<Float>] = []
    private var satVelBuffer: [SIMD3<Float>] = []
    private var satIdxBuffer: [Int] = []
    
    init() {
        OrbitalData.registerComponent()
        self.system = PhysicsSolver(settings: settings, earthRadius: earthRadius)
        
        self.satelliteMaterial = UnlitMaterial(color: UIColor(settings.satelliteColor))
        self.satelliteMesh = .generateBox(size: 2.25)
        
        self.debrisBatchSystem = DebrisBatchSystem(maxDebris: 8000, color: UIColor(settings.debrisColor))
        
        satPosBuffer.reserveCapacity(500)
        satVelBuffer.reserveCapacity(500)
        satIdxBuffer.reserveCapacity(500)
        
        setupLighting()
        setupEarth()
        computeEarthSpinRate()

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
        if (currentTime - lastFrameTime) > 0.048 {
            lastFrameTime = currentTime
        }
        
        processCommandQueue()
        guard !isPaused else { return }
        
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        let effectiveEarthMass = earthMass * Float(settings.gravityMultiplier)
        
        updateSatellites(dt: deltaTime, earthMass: effectiveEarthMass)
        updateEarthRotation()
        
        guard physicsTask == nil else { return }
        
        satPosBuffer.removeAll(keepingCapacity: true)
        satVelBuffer.removeAll(keepingCapacity: true)
        satIdxBuffer.removeAll(keepingCapacity: true)
        
        for (i, sat) in satellites.enumerated() where sat.isEnabled {
            satPosBuffer.append(sat.position)
            satVelBuffer.append(sat.components[OrbitalData.self]?.velocity ?? .zero)
            satIdxBuffer.append(i)
        }

        let cameraWorldPos = cameraRig?.camera.position(relativeTo: nil) ?? .zero

        physicsTask = Task {
            let frame = await system.step(
                dt: deltaTime,
                earthMass: effectiveEarthMass,
                satellitePositions: satPosBuffer,
                satelliteVelocities: satVelBuffer,
                satelliteIndices: satIdxBuffer,
                cameraPosition: cameraWorldPos
            )
            guard !Task.isCancelled else {
                self.physicsTask = nil
                return
            }
            self.applySimulationFrame(frame)
            self.physicsTask = nil
        }
    }
    
    private func applySimulationFrame(_ frame: SimulationFrame) {
        debrisBatchSystem.commitVertices(from: frame.vertexBuffer)

        for index in frame.killedSatelliteIndices where index < satellites.count {
            if satellites[index].isEnabled {
                satellites[index].isEnabled = false
                activeSatelliteCount -= 1
            }
        }

        frameCounter += 1
        if frameCounter % 30 == 0 {
            simulationStats = SimStats(debris: frame.count, satellites: activeSatelliteCount)
        }
    }
    
    private func updateSatellites(dt: Float, earthMass: Float) {
        for entity in satellites where entity.isEnabled {
            guard var data = entity.components[OrbitalData.self] else { continue }
            let pos = entity.position
            let distSq = length_squared(pos)
            
            let invDist = simd_rsqrt(distSq)
            let factor = -earthMass * invDist * invDist * invDist * dt
            
            data.velocity   += pos * factor
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }
    
    private static let spinToOrbitRatio: Float = 1.4814

    private func updateEarthRotation() {
        let deltaTime = (1.0 / 300.0) * Float(settings.timeScale)
        earthEntity?.orientation *= simd_quatf(angle: earthSpinRate * deltaTime, axis: [0, 1, 0])
    }

    private func computeEarthSpinRate() {
        let GM = gravitationalConstant * earthMass * Float(settings.gravityMultiplier)
        let r = Float(settings.orbitAltitude)
        let orbitalOmega = (GM > 0 && r > 0) ? sqrt(GM / (r * r * r)) : 0
        earthSpinRate = Self.spinToOrbitRatio * orbitalOmega
    }
    
    func queueCommand(_ command: EngineCommand) {
        switch command {
        case .reset(let count): pendingResetCount = count
        case .detonate: pendingDetonate = true
        case .updateSettings(let newS): pendingSettings = newS
        }
    }
    
    private func processCommandQueue() {
        if let newS = pendingSettings {
            handleSettingsUpdate(newS)
            pendingSettings = nil
        }
        
        if let count = pendingResetCount {
            resetUniverse(satelliteCount: count)
            pendingResetCount = nil
        }
        
        if pendingDetonate {
            triggerRandomExplosion()
            pendingDetonate = false
        }
    }
    
    private func resetUniverse(satelliteCount: Int) {
        physicsTask?.cancel()
        physicsTask = nil

        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll()
        activeSatelliteCount = 0

        Task { await system.reset() }
        debrisBatchSystem.clear()

        spawnSatellites(count: satelliteCount)
        activeSatelliteCount = satellites.count
        cameraRig?.reset()

        simulationStats = SimStats(debris: 0, satellites: activeSatelliteCount)
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
        activeSatelliteCount -= 1
        Task { await system.spawnExplosion(at: victim.position, velocity: data.velocity) }
    }
    
    private func handleSettingsUpdate(_ newSettings: SimSettings) {
        let colorChanged = settings.satelliteColor != newSettings.satelliteColor ||
                           settings.debrisColor != newSettings.debrisColor
        let visualsChanged = settings.satelliteScale != newSettings.satelliteScale ||
                             settings.showSatellites != newSettings.showSatellites
        let lightingChanged = settings.useOmniLight != newSettings.useOmniLight
        
        let orbitChanged = settings.orbitAltitude != newSettings.orbitAltitude ||
                           settings.gravityMultiplier != newSettings.gravityMultiplier

        self.settings = newSettings

        if lightingChanged { updateLightingMode() }
        if colorChanged    { updateMaterials() }
        if visualsChanged  { updateSatelliteVisuals() }
        if orbitChanged    { computeEarthSpinRate() }
        
        arView?.environment.background = .color(UIColor(settings.backgroundColor))
        earthEntity?.isEnabled = newSettings.showEarth
        debrisBatchSystem.entity.isEnabled = newSettings.showDebris
        
        Task { await system.updateSettings(newSettings) }
    }
    
    private func updateMaterials() {
        self.satelliteMaterial = UnlitMaterial(color: UIColor(settings.satelliteColor))
        
        let sharedSatelliteMaterials: [Material] = [self.satelliteMaterial]

        for sat in satellites {
            guard var comp = sat.components[ModelComponent.self] else { continue }
            
            comp.materials = sharedSatelliteMaterials
            sat.components.set(comp)
        }
        
        debrisBatchSystem.updateColor(UIColor(settings.debrisColor))
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
            mainSun.light.intensity = 4250
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
        mainSun.light.intensity = 5000
        mainSun.look(at: [0, 0, 0], from: [500, 0, -500], relativeTo: nil)
        rootAnchor.addChild(mainSun)
    }
    
    private func setupEarth() {
        let earthMesh = MeshResource.generateSphere(radius: earthRadius)
        var earthMaterial = PhysicallyBasedMaterial()
        
        earthMaterial.roughness = 0.675
        earthMaterial.metallic = 0.0
        earthMaterial.baseColor = .init(tint: .black)
        
        let earth = ModelEntity(mesh: earthMesh, materials: [earthMaterial])
        earth.orientation = simd_quatf(angle: 23.5 * .pi / 180, axis: [0, 0, 1])
        self.earthEntity = earth
        rootAnchor.addChild(earth)
        
        let atmMesh = MeshResource.generateSphere(radius: earthRadius + 4.0)
        var atmMat = PhysicallyBasedMaterial()
        atmMat.baseColor = .init(tint: UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0))
        atmMat.roughness = 1.0
        atmMat.metallic = 0.0
        atmMat.specular = 0.5
        atmMat.blending = .transparent(opacity: 0.175)
        
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
            async let loadedSpecular = try? TextureResource(named: "earth_specular")
            async let loadedNormal = try? TextureResource(named: "earth_normal")
            
            self.aoTexture = await loadedAO
            
            if !self.settings.useOmniLight, let tex = self.aoTexture {
                earthMaterial.ambientOcclusion = .init(texture: .init(tex))
                atmMat.ambientOcclusion = .init(texture: .init(tex))
            }
            
            if let tex = await loadedEarth {
                earthMaterial.baseColor = .init(tint: .white, texture: .init(tex))
            }
            
            if let tex = await loadedSpecular {
                earthMaterial.specular = .init(texture: .init(tex))
            }
            
            if let tex = await loadedNormal {
                earthMaterial.normal = .init(texture: .init(tex))
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
