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
    
    var satelliteColor: Color
    var debrisColor: Color
    var backgroundColor: Color
    
    var maxDebris: Int
    var useRandomInclination: Bool
    var satelliteScale: Double
    var debrisScale: Double
    var gravityMultiplier: Double
    var orbitAltitude: Double
    var orbitVariance: Double
    var useOmniLight: Bool
    var showEarth: Bool
}

extension SimSettings {
    static let defaults = SimSettings(
        debrisPerCollision: 5,
        
        explosionForce: 1.0,
        
        collisionRadius: 3.0,
        
        spreadTangential: 0.1,
        spreadVertical: 0.8,
        spreadRadial: 0.1,
        
        timeScale: 1.0,
        showSatellites: true,
        
        satelliteColor: .green,
        debrisColor: .white,
        backgroundColor: .black,
        
        maxDebris: 5000,
        useRandomInclination: true,
        satelliteScale: 1.0,
        debrisScale: 1.0,
        gravityMultiplier: 1.0,
        orbitAltitude: 120,
        orbitVariance: 2.0,
        useOmniLight: false,
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
    var satelliteCount: Double
    var orbitAltitude: Double
    var orbitVariance: Double
    var useRandomInclination: Bool
    
    var maxDebris: Double
    var debrisPerCollision: Double
    
    static let defaults = PopulationDraft(
        satelliteCount: 500,
        orbitAltitude: SimSettings.defaults.orbitAltitude,
        orbitVariance: SimSettings.defaults.orbitVariance,
        useRandomInclination: SimSettings.defaults.useRandomInclination,
        maxDebris: Double(SimSettings.defaults.maxDebris),
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
    @Published private(set) var activeOrbitAltitude: Double = SimSettings.defaults.orbitAltitude
    @Published private(set) var activeOrbitVariance: Double = SimSettings.defaults.orbitVariance
    @Published private(set) var activeUseRandomInclination: Bool = SimSettings.defaults.useRandomInclination
    
    @Published var timeScale: Double = SimSettings.defaults.timeScale { didSet { syncSettings() } }
    @Published var gravityMultiplier: Double = SimSettings.defaults.gravityMultiplier { didSet { syncSettings() } }
    @Published var explosionForce: Double = SimSettings.defaults.explosionForce { didSet { syncSettings() } }
    @Published var collisionRadius: Double = SimSettings.defaults.collisionRadius { didSet { syncSettings() } }
    
    @Published var spreadTangential: Double = SimSettings.defaults.spreadTangential { didSet { syncSettings() } }
    @Published var spreadVertical: Double = SimSettings.defaults.spreadVertical { didSet { syncSettings() } }
    @Published var spreadRadial: Double = SimSettings.defaults.spreadRadial { didSet { syncSettings() } }
    
    @Published var isCameraLocked: Bool = false
    @Published var showSatellites: Bool = SimSettings.defaults.showSatellites { didSet { syncSettings() } }
    @Published var satelliteColor: Color = .cyan { didSet { syncSettings() } }
    @Published var debrisColor: Color = .red { didSet { syncSettings() } }
    @Published var backgroundColor: Color = .black { didSet { syncSettings() } }
    @Published var satelliteScale: Double = SimSettings.defaults.satelliteScale { didSet { syncSettings() } }
    @Published var debrisScale: Double = SimSettings.defaults.debrisScale { didSet { syncSettings() } }
    @Published var useOmniLight: Bool = SimSettings.defaults.useOmniLight { didSet { syncSettings() } }
    @Published var showEarth: Bool = SimSettings.defaults.showEarth { didSet { syncSettings() } }
    
    @Published var showStats: Bool = true
    @Published var showCollisionAlert: Bool = false
    @Published var isPaused: Bool = false { didSet { engine.isPaused = isPaused } }
    
    init() {
        engine.$simulationStats
            .receive(on: RunLoop.main)
            .assign(to: &telemetry.$stats)
        
        engine.onCinematicEvent = { [weak self] in
            Task { @MainActor in self?.showCollisionAlert = true }
        }
        
        resetSettingsToDefaults()
        resetSimulation()
    }
    
    
    func resetSimulation() {
        let limit = draft.safeSatelliteLimit()
        if draft.satelliteCount > limit { draft.satelliteCount = limit }
        
        activeSatelliteCount = draft.satelliteCount
        activeOrbitAltitude = draft.orbitAltitude
        activeOrbitVariance = draft.orbitVariance
        activeUseRandomInclination = draft.useRandomInclination
        
        syncSettings()
        
        engine.queueCommand(.reset(Int(activeSatelliteCount)))
        dismissCollisionAlert()
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
            
            satelliteColor: satelliteColor,
            debrisColor: debrisColor,
            backgroundColor: backgroundColor,
            
            maxDebris: Int(draft.maxDebris),
            
            useRandomInclination: activeUseRandomInclination,
            
            satelliteScale: satelliteScale,
            debrisScale: debrisScale,
            gravityMultiplier: gravityMultiplier,
            
            orbitAltitude: activeOrbitAltitude,
            orbitVariance: activeOrbitVariance,
            
            useOmniLight: useOmniLight,
            showEarth: showEarth
        )
        engine.queueCommand(.updateSettings(settings))
    }
    
    func resetSettingsToDefaults() {
        let d = SimSettings.defaults
        isCameraLocked = false
        timeScale = d.timeScale
        explosionForce = d.explosionForce
        collisionRadius = d.collisionRadius
        satelliteScale = d.satelliteScale
        debrisScale = d.debrisScale
        gravityMultiplier = d.gravityMultiplier
        
        spreadTangential = d.spreadTangential
        spreadVertical = d.spreadVertical
        spreadRadial = d.spreadRadial
        
        satelliteColor = .green
        debrisColor = .white
        backgroundColor = .black
        
        useOmniLight = d.useOmniLight
        showEarth = d.showEarth
        
        draft = PopulationDraft.defaults
        
    }
    
    func attachToView(_ arView: ARView) { engine.attach(to: arView) }
    func togglePause() { isPaused.toggle() }
    func pauseSimulation() { isPaused = true }
    func resumeSimulation() { isPaused = false }
    func triggerDetonation() { engine.queueCommand(.detonate) }
    func dismissCollisionAlert() { withAnimation { showCollisionAlert = false; resetCamera(); isPaused = false } }
    
    func resetCamera() { engine.resetCamera() }
    func rotateCamera(deltaX: Float, deltaY: Float) { engine.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { engine.zoomCamera(scaleFactor: scaleFactor) }
    func setSettingsPanel(isOpen: Bool, ratio: Double, aspectRatio: Double) {
        engine.setCameraOffset(ratio: isOpen ? Float(ratio) : 0, aspectRatio: Float(aspectRatio))
    }
}
