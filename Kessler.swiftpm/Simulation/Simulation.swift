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

@MainActor
class Simulation: ObservableObject {
    
    let engine = PhysicsEngine()
    let telemetry = Telemetry()
    private var cancellables = Set<AnyCancellable>()
    
    
    @Published var draftMaxDebris: Double = Double(SimSettings.defaults.maxDebris)
    @Published var draftSatelliteCount: Double = 350
    @Published var draftDebrisPerCollision: Double = SimSettings.defaults.debrisPerCollision
    
    @Published private(set) var activeSatelliteCount: Double = 350
    @Published private(set) var activeMaxDebris: Double = Double(SimSettings.defaults.maxDebris)
    
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
    
    @Published var stats = SimStats()
    @Published var isPaused: Bool = false { didSet { engine.isPaused = isPaused } }
    @Published var currentFact: SpaceFact? = nil
    
    init() {
        engine.$simulationStats
            .receive(on: RunLoop.main)
            .assign(to: &telemetry.$stats)
        
        draftMaxDebris = 3000
        draftDebrisPerCollision = 5
        
        let safeSatLimit = floor(draftMaxDebris / (draftDebrisPerCollision * 2))
        
        draftSatelliteCount = min(350, safeSatLimit)
        
        activeSatelliteCount = draftSatelliteCount
        activeMaxDebris = draftMaxDebris
        
        syncSettings()
        engine.queueCommand(.reset(Int(activeSatelliteCount)))
    }
    
    private enum ParamType { case maxDebris, satellites, debrisPerCrash }
    
    private func roundToStep(_ value: Double, step: Double) -> Double {
        return round(value / step) * step
    }
    
    private func enforceBalance(changing: ParamType) {
        
        let debrisGeneratedPerCrash = draftDebrisPerCollision * 2
        let maxSafeSatellites = floor(draftMaxDebris / debrisGeneratedPerCrash)
        
        switch changing {
        case .maxDebris, .debrisPerCrash:
            if draftSatelliteCount > maxSafeSatellites {
                draftSatelliteCount = roundToStep(maxSafeSatellites, step: 25)
            }
            
        case .satellites:
            if draftSatelliteCount > maxSafeSatellites {
                draftSatelliteCount = roundToStep(maxSafeSatellites, step: 25)
            }
        }
    }
    
    func syncSettings() {
        let settings = SimSettings(
            debrisPerCollision: draftDebrisPerCollision,
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
        activeSatelliteCount = draftSatelliteCount
        activeMaxDebris = draftMaxDebris
        
        syncSettings()
        engine.queueCommand(.reset(Int(activeSatelliteCount)))
    }
    
    func setSettingsOpen(_ isOpen: Bool) { engine.setSidePanelOpen(isOpen) }
    func pauseSimulation() { isPaused = true }
    func resumeSimulation() { isPaused = false; currentFact = nil }
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
        
        draftMaxDebris = Double(d.maxDebris)
        draftDebrisPerCollision = d.debrisPerCollision
        
        let safeSatLimit = floor(draftMaxDebris / (draftDebrisPerCollision * 2))
        draftSatelliteCount = min(300, safeSatLimit)
    }
}
