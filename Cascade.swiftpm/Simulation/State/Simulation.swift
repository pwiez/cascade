//
//  Simulation.swift
//  Cascade
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI
import RealityKit
import Combine
import Observation

struct SimSettings {
    var debrisPerCollision: Double
    var explosionForce: Double
    var collisionRadius: Double

    var spreadTangential: Double
    var spreadVertical: Double
    var spreadRadial: Double

    var timeScale: Double
    var showSatellites: Bool

    var satelliteColor: Color
    var debrisColor: Color
    var backgroundColor: Color

    var maxDebris: Int
    var eliminationRadius: Double
    var useRandomInclination: Bool
    var satelliteScale: Double
    var debrisScale: Double
    var gravityMultiplier: Double
    var orbitAltitude: Double
    var orbitVariance: Double
    var useOmniLight: Bool
    var showEarth: Bool
    var showDebris: Bool
    var debrisRotation: Bool
}

extension SimSettings {
    static let defaults = SimSettings(
        debrisPerCollision: 7,
        explosionForce: 0.7,
        collisionRadius: 1.0,
        spreadTangential: 0.1,
        spreadVertical: 0.6,
        spreadRadial: 0.1,
        timeScale: 1.0,
        showSatellites: true,
        satelliteColor: Color(red: 0.108, green: 0.725, blue: 0.229),
        debrisColor: .red,
        backgroundColor: .black,
        maxDebris: 5000,
        eliminationRadius: 600,
        useRandomInclination: true,
        satelliteScale: 1.0,
        debrisScale: 1.0,
        gravityMultiplier: 1.0,
        orbitAltitude: 290,
        orbitVariance: 10.0,
        useOmniLight: false,
        showEarth: true,
        showDebris: true,
        debrisRotation: true,
    )
}

@MainActor @Observable
final class Telemetry {
    var stats = SimStats()
}

struct SimStats {
    var debris: Int = 0
    var satellites: Int = 0
}

enum EngineCommand {
    case reset(Int)
    case detonate
    case updateSettings(SimSettings)
}

struct PopulationDraft {
    var satelliteCount: Double
    var orbitAltitude: Double
    var orbitVariance: Double
    var useRandomInclination: Bool

    static let defaults = PopulationDraft(
        satelliteCount: 300,
        orbitAltitude: SimSettings.defaults.orbitAltitude,
        orbitVariance: SimSettings.defaults.orbitVariance,
        useRandomInclination: SimSettings.defaults.useRandomInclination
    )
}

@MainActor @Observable
final class Simulation {

    @ObservationIgnored private let controller = SceneController()
    let telemetry = Telemetry()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    var draft = PopulationDraft.defaults

    private(set) var activeSatelliteCount: Double = PopulationDraft.defaults.satelliteCount
    private(set) var activeOrbitAltitude: Double = SimSettings.defaults.orbitAltitude
    private(set) var activeOrbitVariance: Double = SimSettings.defaults.orbitVariance
    private(set) var activeUseRandomInclination: Bool = SimSettings.defaults.useRandomInclination

    var timeScale: Double = SimSettings.defaults.timeScale { didSet { syncSettings() } }
    var gravityMultiplier: Double = SimSettings.defaults.gravityMultiplier { didSet { syncSettings() } }
    var explosionForce: Double = SimSettings.defaults.explosionForce { didSet { syncSettings() } }
    var collisionRadius: Double = SimSettings.defaults.collisionRadius { didSet { syncSettings() } }

    var spreadTangential: Double = SimSettings.defaults.spreadTangential { didSet { syncSettings() } }
    var spreadVertical: Double = SimSettings.defaults.spreadVertical { didSet { syncSettings() } }
    var spreadRadial: Double = SimSettings.defaults.spreadRadial { didSet { syncSettings() } }

    var debrisPerCollision: Double = SimSettings.defaults.debrisPerCollision { didSet { syncSettings() } }
    var maxDebris: Double = Double(SimSettings.defaults.maxDebris) { didSet { syncSettings() } }
    var eliminationRadius: Double = SimSettings.defaults.eliminationRadius { didSet { syncSettings() } }

    var isCameraEnabled: Bool = false
    var showSatellites: Bool = SimSettings.defaults.showSatellites { didSet { syncSettings() } }
    var satelliteColor: Color = .cyan { didSet { syncSettings() } }
    var debrisColor: Color = .red { didSet { syncSettings() } }
    var backgroundColor: Color = .black { didSet { syncSettings() } }
    var satelliteScale: Double = SimSettings.defaults.satelliteScale { didSet { syncSettings() } }
    var debrisScale: Double = SimSettings.defaults.debrisScale { didSet { syncSettings() } }
    var debrisRotation: Bool = SimSettings.defaults.debrisRotation { didSet { syncSettings() } }
    var useOmniLight: Bool = SimSettings.defaults.useOmniLight { didSet { syncSettings() } }
    var showEarth: Bool = SimSettings.defaults.showEarth { didSet { syncSettings() } }
    var showDebris: Bool = SimSettings.defaults.showDebris { didSet { syncSettings() } }

    var showStats: Bool = true
    var isPaused: Bool = true { didSet { controller.isPaused = isPaused } }

    @ObservationIgnored private var isBatchingUpdates = false

    private(set) var hasStarted: Bool = false
    private(set) var initialSatelliteCount: Int = 0

    init() {
        controller.$simulationStats
            .receive(on: RunLoop.main)
            .sink { [weak self] stats in
                self?.telemetry.stats = stats
            }
            .store(in: &cancellables)

        resetSettingsToDefaults()
    }

    func startSimulation() {
        guard !hasStarted else { return }
        hasStarted = true
        resetSimulation()
    }

    func resetSimulation() {
        isPaused = true

        activeSatelliteCount = draft.satelliteCount
        activeOrbitAltitude = draft.orbitAltitude
        activeOrbitVariance = draft.orbitVariance
        activeUseRandomInclination = draft.useRandomInclination
        initialSatelliteCount = Int(activeSatelliteCount)

        syncSettings()
        controller.queueCommand(.reset(Int(activeSatelliteCount)))
    }

    func syncSettings() {
        guard !isBatchingUpdates else { return }
        let effectiveHitbox = collisionRadius + ((satelliteScale - 1.0) * 0.25)
        let settings = SimSettings(
            debrisPerCollision: debrisPerCollision,
            explosionForce: explosionForce,
            collisionRadius: effectiveHitbox,
            spreadTangential: spreadTangential,
            spreadVertical: spreadVertical,
            spreadRadial: spreadRadial,
            timeScale: timeScale,
            showSatellites: showSatellites,
            satelliteColor: satelliteColor,
            debrisColor: debrisColor,
            backgroundColor: backgroundColor,
            maxDebris: Int(maxDebris),
            eliminationRadius: eliminationRadius,
            useRandomInclination: activeUseRandomInclination,
            satelliteScale: satelliteScale,
            debrisScale: debrisScale,
            gravityMultiplier: gravityMultiplier,
            orbitAltitude: activeOrbitAltitude,
            orbitVariance: activeOrbitVariance,
            useOmniLight: useOmniLight,
            showEarth: showEarth,
            showDebris: showDebris,
            debrisRotation: debrisRotation
        )
        controller.queueCommand(.updateSettings(settings))
    }

    func resetSettingsToDefaults() {
        isBatchingUpdates = true
        let d = SimSettings.defaults
        isCameraEnabled = true
        timeScale = d.timeScale
        explosionForce = d.explosionForce
        collisionRadius = d.collisionRadius
        eliminationRadius = d.eliminationRadius
        satelliteScale = d.satelliteScale
        debrisScale = d.debrisScale
        gravityMultiplier = d.gravityMultiplier
        spreadTangential = d.spreadTangential
        spreadVertical = d.spreadVertical
        spreadRadial = d.spreadRadial
        satelliteColor = d.satelliteColor
        debrisColor = d.debrisColor
        backgroundColor = d.backgroundColor
        useOmniLight = d.useOmniLight
        showEarth = d.showEarth
        showDebris = d.showDebris
        draft = PopulationDraft.defaults
        isBatchingUpdates = false
        syncSettings()
    }

    func attachToView(_ arView: ARView) { controller.attach(to: arView) }

    func togglePause()       { isPaused.toggle() }
    func pauseSimulation()   { isPaused = true }
    func resumeSimulation()  { isPaused = false }
    func triggerDetonation() { controller.queueCommand(.detonate) }

    func resetCamera()                              { controller.resetCamera() }
    func rotateCamera(deltaX: Float, deltaY: Float) { controller.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float)             { controller.zoomCamera(scaleFactor: scaleFactor) }
    func setSettingsPanel(isOpen: Bool, ratio: Double, aspectRatio: Double) {
        controller.setCameraOffset(ratio: isOpen ? Float(ratio) : 0, aspectRatio: Float(aspectRatio))
    }
}
