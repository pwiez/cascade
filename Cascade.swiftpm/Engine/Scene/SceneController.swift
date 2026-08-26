//
//  SceneController.swift
//  Cascade
//
//  Created by Pedro Wiezel on 09/02/26.
//

import Combine
import RealityKit
import UIKit
import simd

@MainActor
final class SceneController {

    var onStatsChange: ((SimStats) -> Void)?

    var isPaused = true

    private var settings = EngineSettings(sim: .defaults, scenario: .defaults)
    private let solver: PhysicsSolver

    // MARK: World constants
    private let earthRadius: Float = 240.0
    private let earthMass: Float = 150_000
    private let gravitationalConstant: Float = 1.0

    private static let spinToOrbitRatio: Float = 1.4814

    private static let fixedTimeStep: Float = 1.0 / 300.0

    private static let frameInterval: TimeInterval = 1.0 / 60.0

    // MARK: Scene
    private weak var arView: ARView?
    private var sceneUpdateSubscription: (any Cancellable)?
    private var cameraRig: CameraRig?
    private let rootAnchor = AnchorEntity(world: .zero)

    private let mainSun = DirectionalLight()
    private var earthEntity: ModelEntity?
    private var atmosphereEntity: ModelEntity?
    private var ambientOcclusionTexture: TextureResource?
    private var earthSpinRate: Float = 0
    private var earthSetupTask: Task<Void, Never>?

    private var satellites: [ModelEntity] = []
    private var satelliteMaterial: UnlitMaterial
    private let satelliteMesh: MeshResource
    private let debrisBatchSystem: DebrisBatchSystem

    // MARK: Frame state
    private var physicsTask: Task<Void, Never>?

    private var solverQueue: Task<Void, Never> = Task {}

    private var lastFrameTime: TimeInterval = 0
    private var frameCounter = 0
    private var activeSatelliteCount = 0

    private var pendingResetCount: Int?
    private var pendingDetonate = false
    private var pendingSettings: EngineSettings?

    private var satPosBuffer: [SIMD3<Float>] = []
    private var satVelBuffer: [SIMD3<Float>] = []
    private var satIdxBuffer: [Int] = []

    init() {
        OrbitalData.registerComponent()

        solver = PhysicsSolver(settings: settings, earthRadius: earthRadius)
        satelliteMaterial = UnlitMaterial(color: UIColor(settings.sim.satelliteColor))
        satelliteMesh = .generateBox(size: 2.25)
        debrisBatchSystem = DebrisBatchSystem(
            maxDebris: Capacity.maxDebris,
            color: UIColor(settings.sim.debrisColor)
        )

        satPosBuffer.reserveCapacity(Capacity.maxSatellites)
        satVelBuffer.reserveCapacity(Capacity.maxSatellites)
        satIdxBuffer.reserveCapacity(Capacity.maxSatellites)

        setupLighting()
        setupEarth()
        computeEarthSpinRate()

        rootAnchor.addChild(debrisBatchSystem.entity)
    }

    deinit {
        earthSetupTask?.cancel()
        physicsTask?.cancel()
    }

    // MARK: - Attachment

    func attach(to view: ARView) {
        arView = view

        if cameraRig == nil {
            cameraRig = CameraRig(rootAnchor: rootAnchor)
        }
        if rootAnchor.parent == nil {
            view.scene.addAnchor(rootAnchor)
        }

        view.environment.background = .color(UIColor(settings.sim.backgroundColor))

        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.runSimulationFrame()
        }
    }

    // MARK: - Frame loop

    private func runSimulationFrame() {
        guard tickFrameClock() else { return }

        processCommandQueue()
        guard !isPaused else { return }

        let deltaTime = Self.fixedTimeStep * Float(settings.sim.timeScale)
        let effectiveEarthMass = earthMass * Float(settings.sim.gravityMultiplier)

        updateSatellites(dt: deltaTime, earthMass: effectiveEarthMass)
        updateEarthRotation(dt: deltaTime)

        guard physicsTask == nil else { return }

        captureSatelliteState()
        let cameraPosition = cameraRig?.camera.position(relativeTo: nil) ?? .zero
        let positions = satPosBuffer
        let velocities = satVelBuffer
        let indices = satIdxBuffer
        let queue = solverQueue

        physicsTask = Task { [solver] in
            await queue.value
            let frame = await solver.step(
                dt: deltaTime,
                earthMass: effectiveEarthMass,
                satellitePositions: positions,
                satelliteVelocities: velocities,
                satelliteIndices: indices,
                cameraPosition: cameraPosition
            )
            guard !Task.isCancelled else {
                self.physicsTask = nil
                return
            }
            self.apply(frame)
            self.physicsTask = nil
        }
    }

    private func tickFrameClock() -> Bool {
        let now = CACurrentMediaTime()
        if lastFrameTime == 0 { lastFrameTime = now }
        guard now - lastFrameTime >= Self.frameInterval else { return false }

        lastFrameTime += Self.frameInterval
        if now - lastFrameTime > Self.frameInterval * 3 {
            lastFrameTime = now
        }
        return true
    }

    private func captureSatelliteState() {
        satPosBuffer.removeAll(keepingCapacity: true)
        satVelBuffer.removeAll(keepingCapacity: true)
        satIdxBuffer.removeAll(keepingCapacity: true)

        for (index, satellite) in satellites.enumerated() where satellite.isEnabled {
            satPosBuffer.append(satellite.position)
            satVelBuffer.append(satellite.components[OrbitalData.self]?.velocity ?? .zero)
            satIdxBuffer.append(index)
        }
    }

    private func apply(_ frame: SimulationFrame) {
        debrisBatchSystem.commitVertices(from: frame.vertexBuffer)

        for index in frame.killedSatelliteIndices where index < satellites.count {
            guard satellites[index].isEnabled else { continue }
            satellites[index].isEnabled = false
            activeSatelliteCount -= 1
        }

        frameCounter += 1
        if frameCounter % 30 == 0 {
            onStatsChange?(SimStats(debris: frame.debrisCount, satellites: activeSatelliteCount))
        }
    }

    private func updateSatellites(dt: Float, earthMass: Float) {
        for entity in satellites where entity.isEnabled {
            guard var data = entity.components[OrbitalData.self] else { continue }

            let position = entity.position
            let inverseDistance = simd_rsqrt(length_squared(position))
            let factor = -earthMass * inverseDistance * inverseDistance * inverseDistance * dt

            data.velocity += position * factor
            entity.position += data.velocity * dt
            entity.components[OrbitalData.self] = data
        }
    }

    private func updateEarthRotation(dt: Float) {
        earthEntity?.orientation *= simd_quatf(angle: earthSpinRate * dt, axis: [0, 1, 0])
    }

    private func computeEarthSpinRate() {
        let gm = gravitationalConstant * earthMass * Float(settings.sim.gravityMultiplier)
        let radius = Float(settings.scenario.orbitAltitude)
        let orbitalOmega = (gm > 0 && radius > 0) ? sqrt(gm / (radius * radius * radius)) : 0
        earthSpinRate = Self.spinToOrbitRatio * orbitalOmega
    }

    // MARK: - Commands

    func queueCommand(_ command: EngineCommand) {
        switch command {
        case .reset(let count): pendingResetCount = count
        case .detonate: pendingDetonate = true
        case .updateSettings(let newSettings): pendingSettings = newSettings
        }
    }

    private func processCommandQueue() {
        if let newSettings = pendingSettings {
            handleSettingsUpdate(newSettings)
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

    private func onSolver(_ work: @escaping @Sendable (PhysicsSolver) async -> Void) {
        let previous = solverQueue
        let solver = self.solver
        solverQueue = Task {
            await previous.value
            await work(solver)
        }
    }

    private func resetUniverse(satelliteCount: Int) {
        physicsTask?.cancel()
        physicsTask = nil

        satellites.forEach { $0.removeFromParent() }
        satellites.removeAll(keepingCapacity: true)

        onSolver { await $0.reset() }
        debrisBatchSystem.clear()

        spawnSatellites(count: satelliteCount)
        activeSatelliteCount = satellites.count
        cameraRig?.reset()

        onStatsChange?(SimStats(debris: 0, satellites: activeSatelliteCount))
    }

    private func triggerRandomExplosion() {
        var victim: ModelEntity?
        var seen = 0
        for satellite in satellites where satellite.isEnabled {
            seen += 1
            if Int.random(in: 0..<seen) == 0 { victim = satellite }
        }

        guard let victim, let data = victim.components[OrbitalData.self] else { return }
        victim.isEnabled = false
        activeSatelliteCount -= 1

        let position = victim.position
        onSolver { await $0.spawnExplosion(at: position, velocity: data.velocity) }
    }

    // MARK: - World building

    private func spawnSatellites(count: Int) {
        let scenario = settings.scenario
        let altitude = Float(scenario.orbitAltitude)
        let variance = Float(scenario.orbitVariance)
        let gm = gravitationalConstant * earthMass * Float(settings.sim.gravityMultiplier)
        let scale = Float(settings.sim.satelliteScale)

        satellites.reserveCapacity(count)

        for i in 0..<count {
            let radius = altitude + .random(in: -variance...variance)
            let orbitalSpeed = sqrt(gm / radius)

            let (position, velocity) = scenario.useRandomInclination
                ? Self.shellOrbit(index: i, count: count, radius: radius, speed: orbitalSpeed)
                : Self.ringOrbit(index: i, count: count, radius: radius, speed: orbitalSpeed)

            let entity = ModelEntity(mesh: satelliteMesh, materials: [satelliteMaterial])
            entity.scale = SIMD3(repeating: scale)
            entity.position = position
            entity.components.set(OrbitalData(velocity: velocity))

            rootAnchor.addChild(entity)
            satellites.append(entity)
        }
    }

    private static func shellOrbit(index: Int, count: Int, radius: Float, speed: Float)
        -> (position: SIMD3<Float>, velocity: SIMD3<Float>) {

        let goldenAngle: Float = 2.399963229
        let z = 1.0 - (2.0 * Float(index) + 1.0) / Float(count)
        let sinTheta = sqrt(max(0.0, 1.0 - z * z))
        let phi = goldenAngle * Float(index)

        let radial = SIMD3<Float>(sinTheta * cos(phi), z, sinTheta * sin(phi))

        var tangent = SIMD3<Float>(.random(in: -1...1), .random(in: -1...1), .random(in: -1...1))
        tangent -= radial * dot(tangent, radial)
        if length(tangent) < 0.001 {
            tangent = abs(radial.x) < 0.9 ? cross(radial, SIMD3(1, 0, 0)) : cross(radial, SIMD3(0, 1, 0))
        }

        return (radial * radius, normalize(tangent) * speed)
    }

    private static func ringOrbit(index: Int, count: Int, radius: Float, speed: Float)
        -> (position: SIMD3<Float>, velocity: SIMD3<Float>) {

        let anomaly = (Float(index) / Float(count)) * 2.0 * .pi
        return (
            SIMD3(cos(anomaly), 0, sin(anomaly)) * radius,
            SIMD3(-sin(anomaly), 0, cos(anomaly)) * speed
        )
    }

    // MARK: - Settings

    private func handleSettingsUpdate(_ newSettings: EngineSettings) {
        let old = settings
        settings = newSettings

        let colorsChanged = old.sim.satelliteColor != newSettings.sim.satelliteColor
            || old.sim.debrisColor != newSettings.sim.debrisColor
        let visualsChanged = old.sim.satelliteScale != newSettings.sim.satelliteScale
            || old.sim.showSatellites != newSettings.sim.showSatellites
        let lightingChanged = old.sim.useOmniLight != newSettings.sim.useOmniLight
        let orbitChanged = old.scenario.orbitAltitude != newSettings.scenario.orbitAltitude
            || old.sim.gravityMultiplier != newSettings.sim.gravityMultiplier

        if lightingChanged { updateLightingMode() }
        if colorsChanged { updateMaterials() }
        if visualsChanged { updateSatelliteVisuals() }
        if orbitChanged { computeEarthSpinRate() }

        arView?.environment.background = .color(UIColor(newSettings.sim.backgroundColor))
        earthEntity?.isEnabled = newSettings.sim.showEarth
        debrisBatchSystem.entity.isEnabled = newSettings.sim.showDebris

        onSolver { await $0.updateSettings(newSettings) }
    }

    private func updateMaterials() {
        satelliteMaterial = UnlitMaterial(color: UIColor(settings.sim.satelliteColor))
        let materials: [Material] = [satelliteMaterial]

        for satellite in satellites {
            guard var model = satellite.components[ModelComponent.self] else { continue }
            model.materials = materials
            satellite.components.set(model)
        }

        debrisBatchSystem.updateColor(UIColor(settings.sim.debrisColor))
    }

    private func updateSatelliteVisuals() {
        let scale = Float(settings.sim.satelliteScale)
        let showModels = settings.sim.showSatellites

        for entity in satellites {
            let hasModel = entity.components.has(ModelComponent.self)
            if showModels && !hasModel {
                entity.components.set(ModelComponent(mesh: satelliteMesh, materials: [satelliteMaterial]))
            } else if !showModels && hasModel {
                entity.components.remove(ModelComponent.self)
            }
            if entity.scale.x != scale {
                entity.scale = SIMD3(repeating: scale)
            }
        }
    }

    // MARK: - Lighting and Earth

    private func setupLighting() {
        mainSun.light.intensity = 5000
        mainSun.look(at: .zero, from: [500, 0, -500], relativeTo: nil)
        rootAnchor.addChild(mainSun)
    }

    private func updateLightingMode() {
        mainSun.removeFromParent()

        if settings.sim.useOmniLight {
            cameraRig?.camera.addChild(mainSun)
            mainSun.transform = .identity
            mainSun.light.intensity = 4250
        } else {
            rootAnchor.addChild(mainSun)
            mainSun.light.intensity = 5000
            mainSun.look(at: .zero, from: [500, 0, -500], relativeTo: nil)
        }

        guard let earth = earthEntity,
              var model = earth.model,
              var material = model.materials.first as? PhysicallyBasedMaterial else { return }

        if settings.sim.useOmniLight {
            material.ambientOcclusion = PhysicallyBasedMaterial.AmbientOcclusion()
        } else if let texture = ambientOcclusionTexture {
            material.ambientOcclusion = .init(texture: .init(texture))
        }

        model.materials = [material]
        earth.model = model
    }

    private func setupEarth() {
        var earthMaterial = PhysicallyBasedMaterial()
        earthMaterial.roughness = 0.675
        earthMaterial.metallic = 0.0
        earthMaterial.baseColor = .init(tint: .black)

        let earth = ModelEntity(mesh: .generateSphere(radius: earthRadius), materials: [earthMaterial])
        earth.orientation = simd_quatf(angle: 23.5 * .pi / 180, axis: [0, 0, 1])
        earthEntity = earth
        rootAnchor.addChild(earth)

        var atmosphereMaterial = PhysicallyBasedMaterial()
        atmosphereMaterial.baseColor = .init(tint: UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0))
        atmosphereMaterial.roughness = 1.0
        atmosphereMaterial.metallic = 0.0
        atmosphereMaterial.specular = 0.5
        atmosphereMaterial.blending = .transparent(opacity: 0.175)

        let atmosphere = ModelEntity(mesh: .generateSphere(radius: earthRadius + 4.0),
                                     materials: [atmosphereMaterial])
        atmosphereEntity = atmosphere
        earth.addChild(atmosphere)

        earthSetupTask = Task { [weak self] in
            await self?.loadEarthTextures(baseMaterial: earthMaterial, atmosphereMaterial: atmosphereMaterial)
        }
    }

    private func loadEarthTextures(baseMaterial: PhysicallyBasedMaterial,
                                   atmosphereMaterial: PhysicallyBasedMaterial) async {
        var earthMaterial = baseMaterial
        var atmosphere = atmosphereMaterial

        async let albedo = try? await TextureResource(named: "earthmap")
        async let specular = try? await TextureResource(named: "earth_specular")
        async let normal = try? await TextureResource(named: "earth_normal")

        ambientOcclusionTexture = Self.flatAmbientOcclusionTexture()

        if !settings.sim.useOmniLight, let texture = ambientOcclusionTexture {
            earthMaterial.ambientOcclusion = .init(texture: .init(texture))
            atmosphere.ambientOcclusion = .init(texture: .init(texture))
        }
        if let texture = await albedo {
            earthMaterial.baseColor = .init(tint: .white, texture: .init(texture))
        }
        if let texture = await specular {
            earthMaterial.specular = .init(texture: .init(texture))
        }
        if let texture = await normal {
            earthMaterial.normal = .init(texture: .init(texture))
        }

        guard !Task.isCancelled else { return }
        earthEntity?.model?.materials = [earthMaterial]
        atmosphereEntity?.model?.materials = [atmosphere]
    }

    private static let nightSideAmbient: Double = 0.04

    private static func flatAmbientOcclusionTexture() -> TextureResource? {
        let level = UInt8(clamping: Int((nightSideAmbient * 255).rounded()))

        guard let provider = CGDataProvider(data: Data([level]) as CFData),
              let image = CGImage(
                  width: 1, height: 1,
                  bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: 1,
                  space: CGColorSpaceCreateDeviceGray(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                  provider: provider, decode: nil,
                  shouldInterpolate: false, intent: .defaultIntent
              )
        else { return nil }

        return try? TextureResource(
            image: image,
            withName: nil,
            options: .init(semantic: PhysicallyBasedMaterial.AmbientOcclusion.textureSemantic)
        )
    }

    // MARK: - Camera

    func resetCamera() { cameraRig?.reset() }
    func rotateCamera(deltaX: Float, deltaY: Float) { cameraRig?.rotate(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { cameraRig?.zoom(scaleFactor: scaleFactor) }

    func setCameraOffset(ratio: Float, aspectRatio: Float) {
        cameraRig?.setTargetOffset(ratio: ratio, aspectRatio: aspectRatio)
    }
}
