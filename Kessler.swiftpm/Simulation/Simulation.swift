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
    private var cancellables = Set<AnyCancellable>()
    
    
    var maxSafeSatellites: Double {
        let piecesPerBody = Double(min(Int(debrisPerCollision), 20) + 1)
        
        let debrisCostPerSat = (2.0 * piecesPerBody) - 1.0
        
        return floor(maxDebris / max(1.0, debrisCostPerSat))
    }
    
    func enforceSatelliteLimit() {
        if satelliteCount > maxSafeSatellites {
            satelliteCount = maxSafeSatellites
        }
    }
    
    func setSettingsOpen(_ isOpen: Bool) {
            engine.setSidePanelOpen(isOpen)
        }
    
    @Published var satelliteCount: Double = 256 {
        didSet { syncSettingsWithEngine() }
    }
    
    @Published var maxDebris: Double = 3000 {
            didSet {
                enforceSatelliteLimit()
                syncSettingsWithEngine()
            }
        }
    
    @Published var useRandomInclination: Bool = true { didSet { syncSettingsWithEngine() } }
    
    @Published var satelliteScale: Double = 1.0 { didSet { syncSettingsWithEngine() } }
    @Published var debrisScale: Double = 1.0 { didSet { syncSettingsWithEngine() } }
    @Published var useOmniLight: Bool = false { didSet { syncSettingsWithEngine() } }
    
    @Published var debrisPerCollision: Double = 4 {
        didSet {
            enforceSatelliteLimit()
            syncSettingsWithEngine()
        }
    }
    
    @Published var explosionForce: Double = 1.1 { didSet { syncSettingsWithEngine() } }
    @Published var collisionRadius: Double = 1.5 { didSet { syncSettingsWithEngine() } }
    @Published var gravityMultiplier: Double = 1.0 { didSet { syncSettingsWithEngine() } }
    @Published var orbitAltitude: Double = 120.0 { didSet { syncSettingsWithEngine() } }
    
    @Published var spreadTangential: Double = 1 { didSet { syncSettingsWithEngine() } }
    @Published var spreadVertical: Double = 0.6 { didSet { syncSettingsWithEngine() } }
    @Published var spreadRadial: Double = 0.2 { didSet { syncSettingsWithEngine() } }
    
    @Published var timeScale: Double = 0.1 { didSet { syncSettingsWithEngine() } }
    @Published var showSatellites: Bool = true { didSet { syncSettingsWithEngine() } }
    
    @Published var highContrast: Bool = false { didSet { syncSettingsWithEngine() } }
        @Published var showEarth: Bool = true { didSet { syncSettingsWithEngine() } }
        @Published var showStats: Bool = true
    
    @Published var stats = SimStats()
    @Published var isPaused: Bool = false {
        didSet { engine.isPaused = isPaused }
    }
    @Published var currentFact: SpaceFact? = nil
    
    init() {
        engine.$simulationStats
                    .receive(on: RunLoop.main)
                    .assign(to: &$stats)
            
        engine.queueCommand(.reset(256))
        syncSettingsWithEngine()
    }
    
    var debrisCount: Int { stats.debris }
        var activeSatellites: Int { stats.satellites }
    
    func syncSettingsWithEngine() {
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
            useOmniLight: useOmniLight
        )
        engine.queueCommand(.updateSettings(settings))
    }
    
    func pauseSimulation() { isPaused = true }
    func resumeSimulation() { isPaused = false; currentFact = nil }
    
    func triggerDetonation() { engine.queueCommand(.detonate) }
    func resetSimulation() { engine.queueCommand(.reset(Int(satelliteCount))) }
    func resetCamera() { engine.resetCamera() }
    func rotateCamera(deltaX: Float, deltaY: Float) { engine.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { engine.zoomCamera(scaleFactor: scaleFactor) }
    
    func resetSettingsToDefaults() {
        timeScale = 1.0
        debrisPerCollision = 4
        explosionForce = 1.1
        collisionRadius = 1.0
        spreadTangential = 1.0
        spreadVertical = 0.6
        spreadRadial = 0.2
        satelliteCount = 256
        maxDebris = 3000
        useRandomInclination = true
        satelliteScale = 1.0
        debrisScale = 1.0
        gravityMultiplier = 1.0
        orbitAltitude = 120.0
        useOmniLight = false
    }
}
