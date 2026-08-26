//
//  Simulation.swift
//  Cascade
//
//  Created by Pedro Wiezel on 11/02/26.
//

import Observation
import RealityKit

@MainActor @Observable
public final class Simulation {

    public var settings = SimSettings.defaults {
        didSet { pushSettings() }
    }

    public var draft = Scenario.defaults

    public private(set) var active = Scenario.defaults

    public var hasPendingChanges: Bool { draft != active }

    public let telemetry = Telemetry()

    public var isCameraEnabled = true
    public var showStats = true
    public var isPaused = true {
        didSet { controller.isPaused = isPaused }
    }

    public private(set) var hasStarted = false

    @ObservationIgnored private let controller = SceneController()

    public init() {
        controller.onStatsChange = { [weak self] stats in
            self?.telemetry.stats = stats
        }
        pushSettings()
    }

    // MARK: - Lifecycle

    public func startSimulation() {
        guard !hasStarted else { return }
        hasStarted = true
        resetSimulation()
    }

    public func resetSimulation() {
        isPaused = true
        active = draft
        pushSettings()
        controller.queueCommand(.reset(satelliteCount: Int(active.satelliteCount)))
    }

    public func resetSettingsToDefaults() {
        settings = .defaults
        draft = .defaults
        isCameraEnabled = true
    }

    private func pushSettings() {
        controller.queueCommand(.updateSettings(EngineSettings(sim: settings, scenario: active)))
    }

    // MARK: - Playback

    public func pauseSimulation() { isPaused = true }
    public func resumeSimulation() { isPaused = false }
    public func triggerDetonation() { controller.queueCommand(.detonate) }

    // MARK: - Camera

    public func attachToView(_ arView: ARView) { controller.attach(to: arView) }
    public func resetCamera() { controller.resetCamera() }
    public func rotateCamera(deltaX: Float, deltaY: Float) { controller.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    public func zoomCamera(scaleFactor: Float) { controller.zoomCamera(scaleFactor: scaleFactor) }

    public func setSettingsPanel(isOpen: Bool, ratio: Double, aspectRatio: Double) {
        controller.setCameraOffset(ratio: isOpen ? Float(ratio) : 0, aspectRatio: Float(aspectRatio))
    }
}
