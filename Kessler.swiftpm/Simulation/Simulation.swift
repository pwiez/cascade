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
    
    
    @Published var draftMaxDebris: Double = 3000 {
            didSet {
                if draftMaxDebris == oldValue { return }
                
                let rounded = roundToStep(draftMaxDebris, step: 100)
                
                if abs(draftMaxDebris - rounded) > 0.001 {
                    draftMaxDebris = rounded
                } else {
                    enforceBalance(changing: .maxDebris)
                }
            }
        }
    
    @Published var draftSatelliteCount: Double = 350 {
        didSet {
            if draftSatelliteCount == oldValue { return }
            
            let rounded = roundToStep(draftSatelliteCount, step: 25)
            if abs(draftSatelliteCount - rounded) > 0.001 {
                draftSatelliteCount = rounded
            } else {
                enforceBalance(changing: .satellites)
            }
        }
    }
    
    @Published var draftDebrisPerCollision: Double = 5 {
        didSet {
            if draftDebrisPerCollision == oldValue { return }
            
            if draftDebrisPerCollision < 3 { draftDebrisPerCollision = 3; return }
            if draftDebrisPerCollision > 7 { draftDebrisPerCollision = 7; return }
            
            enforceBalance(changing: .debrisPerCrash)
        }
    }
    
    @Published private(set) var activeSatelliteCount: Double = 350
    @Published private(set) var activeMaxDebris: Double = 1500
    
    @Published var useRandomInclination: Bool = true { didSet { syncSettings() } }
    @Published var satelliteScale: Double = 1.0 { didSet { syncSettings() } }
    @Published var debrisScale: Double = 1.0 { didSet { syncSettings() } }
    @Published var useOmniLight: Bool = false { didSet { syncSettings() } }
    @Published var isCameraLocked: Bool = false { didSet { if isCameraLocked { resetCamera() } } }
    
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
        isCameraLocked = false
        timeScale = 1.0
        explosionForce = 1.0
        collisionRadius = 2.0
        
        useRandomInclination = true
        satelliteScale = 1.0
        debrisScale = 1.0
        gravityMultiplier = 1.0
        orbitAltitude = 120.0
        highContrast = false
        showEarth = true
        
        draftMaxDebris = 3000
        draftDebrisPerCollision = 5
        
        let safeSatLimit = floor(draftMaxDebris / (draftDebrisPerCollision * 2))
        draftSatelliteCount = min(300, safeSatLimit)
        
    }
}
