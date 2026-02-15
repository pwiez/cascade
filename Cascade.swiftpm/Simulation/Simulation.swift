import SwiftUI
import RealityKit
import Combine

struct SimSettings {
    var debrisPerCollision: Double
    var explosionForce: Double
    var collisionRadius: Double
    
    var spreadTangential: Double
    var spreadVertical: Double
    var spreadRadial: Double
    
    var timeScale: Double
    var showSatellites: Bool
    
    var maxDebris: Int
    var useRandomInclination: Bool
    var satelliteScale: Double
    var debrisScale: Double
    var gravityMultiplier: Double
    var orbitAltitude: Double
    var useOmniLight: Bool
    var highContrast: Bool
    var showEarth: Bool
}

extension SimSettings {
    static let defaults = SimSettings(
        debrisPerCollision: 5,
        explosionForce: 1.1,
        collisionRadius: 2.0,
        
        spreadTangential: 1.0,
        spreadVertical: 0.6,
        spreadRadial: 0.2,
        
        timeScale: 1.0,
        showSatellites: true,
        
        maxDebris: 3000,
        useRandomInclination: true,
        satelliteScale: 1.0,
        debrisScale: 1.0,
        gravityMultiplier: 1.0,
        orbitAltitude: 120.0,
        useOmniLight: false,
        highContrast: false,
        showEarth: true
    )
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
    var maxDebris: Double
    var satelliteCount: Double
    var debrisPerCollision: Double
    
    static let defaults = PopulationDraft(
        maxDebris: Double(SimSettings.defaults.maxDebris),
        satelliteCount: 300,
        debrisPerCollision: SimSettings.defaults.debrisPerCollision
    )
    
    func safeSatelliteLimit() -> Double {
        return floor(maxDebris / (debrisPerCollision * 2))
    }
}

@MainActor
class Simulation: ObservableObject {
    
    private let engine = PhysicsEngine()
    let telemetry = Telemetry()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var draft = PopulationDraft.defaults
    
    @Published private(set) var activeSatelliteCount: Double = 300
    @Published private(set) var activeMaxDebris: Double = 3000
    
    @Published var showCollisionAlert: Bool = false
    @AppStorage("hasSeenFirstCrash") var hasSeenFirstCrash: Bool = false
    
    @Published var useRandomInclination: Bool = SimSettings.defaults.useRandomInclination { didSet { syncSettings() } }
    @Published var satelliteScale: Double = SimSettings.defaults.satelliteScale { didSet { syncSettings() } }
    @Published var debrisScale: Double = SimSettings.defaults.debrisScale { didSet { syncSettings() } }
    @Published var useOmniLight: Bool = SimSettings.defaults.useOmniLight { didSet { syncSettings() } }
    @Published var isCameraLocked: Bool = false
    
    @Published var explosionForce: Double = SimSettings.defaults.explosionForce { didSet { syncSettings() } }
    @Published var collisionRadius: Double = SimSettings.defaults.collisionRadius { didSet { syncSettings() } }
    @Published var gravityMultiplier: Double = SimSettings.defaults.gravityMultiplier { didSet { syncSettings() } }
    @Published var orbitAltitude: Double = SimSettings.defaults.orbitAltitude { didSet { syncSettings() } }
    
    @Published var spreadTangential: Double = SimSettings.defaults.spreadTangential { didSet { syncSettings() } }
    @Published var spreadVertical: Double = SimSettings.defaults.spreadVertical { didSet { syncSettings() } }
    @Published var spreadRadial: Double = SimSettings.defaults.spreadRadial { didSet { syncSettings() } }
    
    @Published var timeScale: Double = SimSettings.defaults.timeScale { didSet { syncSettings() } }
    @Published var showSatellites: Bool = SimSettings.defaults.showSatellites { didSet { syncSettings() } }
    @Published var highContrast: Bool = SimSettings.defaults.highContrast {
        didSet {
            if highContrast {
                satelliteScale = 2.5
                debrisScale = 2.5
            } else {
                satelliteScale = 1.0
                debrisScale = 1.0
            }
            syncSettings()
        }
    }
    @Published var showEarth: Bool = SimSettings.defaults.showEarth { didSet { syncSettings() } }
    
    @Published var showStats: Bool = true
    @Published var isPaused: Bool = false { didSet { engine.isPaused = isPaused } }
    
    init() {
        engine.$simulationStats
            .receive(on: RunLoop.main)
            .assign(to: &telemetry.$stats)
        
        engine.onCinematicEvent = { [weak self] in
            Task { @MainActor in
                self?.handleCinematicEvent()
            }
        }
        
        resetSettingsToDefaults()
        resetSimulation()
    }
    
    func handleCinematicEvent() {
        
        withAnimation {
            self.showCollisionAlert = true
        }
    }
    
    func dismissCollisionAlert() {
        withAnimation {
            showCollisionAlert = false
            hasSeenFirstCrash = true
            resetCamera()
                        isPaused = false
        }
    }
    
    func attachToView(_ arView: ARView) { engine.attach(to: arView) }
    
    func togglePause() {
        let newState = !isPaused
        isPaused = newState
        engine.setPaused(newState)
    }
    
    func syncSettings() {
        let settings = SimSettings(
            debrisPerCollision: draft.debrisPerCollision,
            explosionForce: explosionForce,
            collisionRadius: collisionRadius,
            spreadTangential: spreadTangential,
            spreadVertical: spreadVertical,
            spreadRadial: spreadRadial,
            timeScale: timeScale,
            showSatellites: showSatellites,
            maxDebris: Int(activeMaxDebris),
            useRandomInclination: useRandomInclination,
            satelliteScale: satelliteScale,
            debrisScale: debrisScale,
            gravityMultiplier: gravityMultiplier,
            orbitAltitude: orbitAltitude,
            useOmniLight: useOmniLight,
            highContrast: highContrast,
            showEarth: showEarth
        )
        engine.queueCommand(.updateSettings(settings))
    }
    
    func resetSimulation() {
        let limit = draft.safeSatelliteLimit()
        if draft.satelliteCount > limit { draft.satelliteCount = limit }
        activeSatelliteCount = draft.satelliteCount
        activeMaxDebris = draft.maxDebris
        syncSettings()
        engine.queueCommand(.reset(Int(activeSatelliteCount)))
        
    }
    
    func setSettingsOpen(_ isOpen: Bool) { engine.setSidePanelOpen(isOpen) }
    func pauseSimulation() { isPaused = true }
    func resumeSimulation() { isPaused = false }
    func triggerDetonation() { engine.queueCommand(.detonate) }
    
    func resetCamera() { engine.resetCamera() }
    func rotateCamera(deltaX: Float, deltaY: Float) { engine.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { engine.zoomCamera(scaleFactor: scaleFactor) }
    
    func resetSettingsToDefaults() {
        let d = SimSettings.defaults
        isCameraLocked = false
        timeScale = d.timeScale
        explosionForce = d.explosionForce
        collisionRadius = d.collisionRadius
        useRandomInclination = d.useRandomInclination
        satelliteScale = d.satelliteScale
        debrisScale = d.debrisScale
        gravityMultiplier = d.gravityMultiplier
        orbitAltitude = d.orbitAltitude
        highContrast = d.highContrast
        showEarth = d.showEarth
        draft = PopulationDraft.defaults
        let limit = draft.safeSatelliteLimit()
        draft.satelliteCount = min(300, limit)
    }
}
