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
        debrisPerCollision: 4,
        explosionForce: 1.0,
        collisionRadius: 1.5,
        spreadTangential: 0.0,
        spreadVertical: 0.7,
        spreadRadial: 0.0,
        timeScale: 1.0,
        showSatellites: true,
        satelliteColor: Color(red: 0.108, green: 0.500, blue: 0.229),
        debrisColor: .red,
        backgroundColor: .black,
        maxDebris: 2000,
        useRandomInclination: true,
        satelliteScale: 2.0,
        debrisScale: 2.0,
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

    static let defaults = PopulationDraft(
        satelliteCount: 150,
        orbitAltitude: SimSettings.defaults.orbitAltitude,
        orbitVariance: SimSettings.defaults.orbitVariance,
        useRandomInclination: SimSettings.defaults.useRandomInclination
    )
}

@MainActor
class Simulation: ObservableObject {

    private let controller = SceneController()
    let telemetry = Telemetry()
    private var cancellables = Set<AnyCancellable>()

    @Published var draft = PopulationDraft.defaults

    @Published private(set) var activeSatelliteCount: Double = PopulationDraft.defaults.satelliteCount
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

    @Published var debrisPerCollision: Double = SimSettings.defaults.debrisPerCollision { didSet { syncSettings() } }
    @Published var maxDebris: Double = Double(SimSettings.defaults.maxDebris) { didSet { syncSettings() } }

    @Published var isCameraEnabled: Bool = false
    @Published var showSatellites: Bool = SimSettings.defaults.showSatellites { didSet { syncSettings() } }
    @Published var satelliteColor: Color = .cyan { didSet { syncSettings() } }
    @Published var debrisColor: Color = .red { didSet { syncSettings() } }
    @Published var backgroundColor: Color = .black { didSet { syncSettings() } }
    @Published var satelliteScale: Double = SimSettings.defaults.satelliteScale { didSet { syncSettings() } }
    @Published var debrisScale: Double = SimSettings.defaults.debrisScale { didSet { syncSettings() } }
    @Published var useOmniLight: Bool = SimSettings.defaults.useOmniLight { didSet { syncSettings() } }
    @Published var showEarth: Bool = SimSettings.defaults.showEarth { didSet { syncSettings() } }

    @Published var showStats: Bool = true
    @Published var isPaused: Bool = true { didSet { controller.isPaused = isPaused } }

    @Published private(set) var hasStarted: Bool = false
    @Published private(set) var initialSatelliteCount: Int = 0

    init() {
        controller.$simulationStats
            .receive(on: RunLoop.main)
            .assign(to: &telemetry.$stats)

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
            useRandomInclination: activeUseRandomInclination,
            satelliteScale: satelliteScale,
            debrisScale: debrisScale,
            gravityMultiplier: gravityMultiplier,
            orbitAltitude: activeOrbitAltitude,
            orbitVariance: activeOrbitVariance,
            useOmniLight: useOmniLight,
            showEarth: showEarth
        )
        controller.queueCommand(.updateSettings(settings))
    }

    func resetSettingsToDefaults() {
        let d = SimSettings.defaults
        isCameraEnabled = true
        timeScale = d.timeScale
        explosionForce = d.explosionForce
        collisionRadius = d.collisionRadius
        satelliteScale = d.satelliteScale
        debrisScale = d.debrisScale
        gravityMultiplier = d.gravityMultiplier
        spreadTangential = d.spreadTangential
        spreadVertical = d.spreadVertical
        spreadRadial = d.spreadRadial
        satelliteColor = Color(red: 0.108, green: 0.500, blue: 0.229)
        debrisColor = .red
        backgroundColor = .black
        useOmniLight = d.useOmniLight
        showEarth = d.showEarth
        draft = PopulationDraft.defaults
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
