//
//  Simulation.swift
//  Cascade
//
//  Created by Pedro Wiezel on 11/02/26.
//

import Observation
import RealityKit

/// The observable façade the whole UI talks to.
///
/// Everything below this line is engine: `SceneController` owns the scene graph
/// on the main actor, `PhysicsSolver` owns the numbers off it. Views never reach
/// past this type, which is what keeps the render loop free of SwiftUI and
/// SwiftUI free of RealityKit.
@MainActor @Observable
public final class Simulation {

    /// Live tunables. Assigning any part of this pushes the whole struct to the
    /// engine — see ``pushSettings()`` for why that is cheaper than it looks.
    public var settings = SimSettings.defaults {
        didSet { pushSettings() }
    }

    /// Scenario values the user is currently editing.
    public var draft = Scenario.defaults

    /// The scenario the running universe was actually built from.
    public private(set) var active = Scenario.defaults

    /// True while `draft` has drifted from `active`, i.e. a restart is needed
    /// before the user's scenario edits mean anything.
    public var hasPendingChanges: Bool { draft != active }

    /// Counts for the on-screen readout, deliberately in their own observable box.
    public let telemetry = Telemetry()

    // View state that never reaches the engine. Keeping it out of `SimSettings`
    // is what stops a HUD toggle from queueing a pointless engine update.
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

    /// Builds the first universe. Safe to call from `onAppear`, which fires again
    /// on some layout changes.
    public func startSimulation() {
        guard !hasStarted else { return }
        hasStarted = true
        resetSimulation()
    }

    /// Applies the pending scenario and rebuilds the universe from scratch.
    public func resetSimulation() {
        isPaused = true
        active = draft
        pushSettings()
        controller.queueCommand(.reset(satelliteCount: Int(active.satelliteCount)))
    }

    /// Restores every tunable and the pending scenario to their shipped values.
    ///
    /// One assignment each, because both are stored whole — there is no list of
    /// properties here to fall out of date.
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

    /// Slides the camera sideways so the settings panel doesn't cover Earth.
    public func setSettingsPanel(isOpen: Bool, ratio: Double, aspectRatio: Double) {
        controller.setCameraOffset(ratio: isOpen ? Float(ratio) : 0, aspectRatio: Float(aspectRatio))
    }
}
