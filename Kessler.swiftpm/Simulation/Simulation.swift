import SwiftUI
import RealityKit
import Combine

struct SimSettings {
    var debrisPerCollision: Double = 0
    var explosionForce: Double = 0
    var collisionRadius: Double = 0
    
    var spreadTangential: Double = 0
    var spreadVertical: Double = 0
    var spreadRadial: Double = 0
    
    var timeScale: Double = 0
    var showSatellites: Bool = true
    
    var maxDebris: Int = 3000
    var useRandomInclination: Bool = true
    var satelliteScale: Double = 1.0
    var debrisScale: Double = 1.0
    var gravityMultiplier: Double = 1.0
    var orbitAltitude: Double = 120.0
    var useOmniLight: Bool = false
    var highContrast: Bool = false
    var showEarth: Bool = true
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

@MainActor
class Simulation: ObservableObject {
    
    let engine = PhysicsEngine()
    let telemetry = Telemetry()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var satelliteCount: Double = 350 { didSet { syncSettings() } }
    @Published var maxDebris: Double = 1500 { didSet { enforceLimit(); syncSettings() } }
    
    @Published var useRandomInclination: Bool = true { didSet { syncSettings() } }
    @Published var satelliteScale: Double = 1.0 { didSet { syncSettings() } }
    @Published var debrisScale: Double = 1.0 { didSet { syncSettings() } }
    @Published var useOmniLight: Bool = false { didSet { syncSettings() } }
    @Published var isCameraLocked: Bool = false {
            didSet {
                if isCameraLocked {
                    resetCamera()
                }
            }
        }
    
    @Published var debrisPerCollision: Double = 5 { didSet { enforceLimit(); syncSettings() } }
    @Published var explosionForce: Double = 10 { didSet { syncSettings() } }
    @Published var collisionRadius: Double = 2 { didSet { syncSettings() } }
    @Published var gravityMultiplier: Double = 1.0 { didSet { syncSettings() } }
    @Published var orbitAltitude: Double = 120.0 { didSet { syncSettings() } }
    
    @Published var spreadTangential: Double = 1 { didSet { syncSettings() } }
    @Published var spreadVertical: Double = 0.6 { didSet { syncSettings() } }
    @Published var spreadRadial: Double = 0.2 { didSet { syncSettings() } }
    
    @Published var timeScale: Double = 1.0 { didSet { syncSettings() } }
    @Published var showSatellites: Bool = true { didSet { syncSettings() } }
    @Published var highContrast: Bool = false {
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
    @Published var showEarth: Bool = true { didSet { syncSettings() } }
    @Published var showStats: Bool = true
    
    @Published var stats = SimStats()
    @Published var isPaused: Bool = false { didSet { engine.isPaused = isPaused } }
    @Published var currentFact: SpaceFact? = nil
    
    init() {
            engine.$simulationStats
                .receive(on: RunLoop.main)
                .assign(to: &telemetry.$stats)
                
            engine.queueCommand(.reset(256))
            syncSettings()
        }
    
    func enforceLimit() {
        let piecesPerBody = Double(min(Int(debrisPerCollision), 20) + 1)
        let debrisCostPerSat = (2.0 * piecesPerBody) - 1.0
        let safeMax = floor(maxDebris / max(1.0, debrisCostPerSat))
        
        if satelliteCount > safeMax {
            satelliteCount = safeMax
        }
    }
    
    func syncSettings() {
        let settings = SimSettings(
            debrisPerCollision: debrisPerCollision,
            explosionForce: explosionForce,
            collisionRadius: collisionRadius,
            spreadTangential: spreadTangential,
            spreadVertical: spreadVertical,
            spreadRadial: spreadRadial,
            timeScale: timeScale,
            showSatellites: showSatellites,
            maxDebris: Int(maxDebris),
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
    
    func setSettingsOpen(_ isOpen: Bool) { engine.setSidePanelOpen(isOpen) }
    func pauseSimulation() { isPaused = true }
    func resumeSimulation() { isPaused = false; currentFact = nil }
    func triggerDetonation() { engine.queueCommand(.detonate) }
    func resetSimulation() { engine.queueCommand(.reset(Int(satelliteCount))) }
    
    func resetCamera() { engine.resetCamera() }
    func rotateCamera(deltaX: Float, deltaY: Float) { engine.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { engine.zoomCamera(scaleFactor: scaleFactor) }
    
    func resetSettingsToDefaults() {
        isCameraLocked = false
        timeScale = 1.0
        debrisPerCollision = 5
        explosionForce = 1.0
        collisionRadius = 2.0
        spreadTangential = 0.9
        spreadVertical = 0.7
        spreadRadial = 0.2
        satelliteCount = 350
        maxDebris = 3000
        useRandomInclination = true
        satelliteScale = 1.0
        debrisScale = 1.0
        gravityMultiplier = 1.0
        orbitAltitude = 120.0
        useOmniLight = false
        highContrast = false
        showEarth = true
    }
}
