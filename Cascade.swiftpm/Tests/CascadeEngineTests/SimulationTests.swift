//
//  SimulationTests.swift
//  CascadeEngineTests
//

import Observation
import RealityKit
import Synchronization
import Testing
@testable import CascadeEngine

@Suite("Simulation UI state and commands")
@MainActor
struct SimulationTests {
    @Test("Initialization supplies settings without starting or resetting the simulation")
    func initializationDoesNotStartPlayback() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)

        #expect(controller.events == [.settings(.defaults, .defaults)])
        #expect(!simulation.hasStarted)
        #expect(simulation.isPaused)
        #expect(simulation.isCameraEnabled)
        #expect(simulation.showStats)
        #expect(simulation.telemetry.stats == SimStats())
        #expect(!simulation.hasPendingChanges)
    }

    @Test("Starting twice does not reset a simulation that has already started")
    func startupIsIdempotent() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        controller.clearEvents()

        simulation.startSimulation()

        #expect(simulation.hasStarted)
        #expect(controller.events == [
            .playback(paused: true),
            .settings(.defaults, .defaults),
            .reset(satelliteCount: 300)
        ])

        simulation.resumeSimulation()
        simulation.draft.satelliteCount = 450
        controller.clearEvents()
        simulation.startSimulation()

        #expect(controller.events.isEmpty)
        #expect(!simulation.isPaused)
        #expect(simulation.active == .defaults)
        #expect(simulation.hasPendingChanges)
    }

    @Test("Restart pauses playback and applies the complete draft before rebuilding")
    func restartAppliesDraftInOrder() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        let scenario = Scenario(
            satelliteCount: 475, orbitAltitude: 310, orbitVariance: 25,
            useRandomInclination: false
        )
        simulation.draft = scenario
        simulation.settings.timeScale = 2
        simulation.resumeSimulation()
        controller.clearEvents()

        #expect(simulation.hasPendingChanges)
        #expect(simulation.active == .defaults)

        simulation.resetSimulation()

        #expect(simulation.isPaused)
        #expect(simulation.active == scenario)
        #expect(simulation.draft == scenario)
        #expect(!simulation.hasPendingChanges)
        #expect(controller.events == [
            .playback(paused: true),
            .settings(simulation.settings, scenario),
            .reset(satelliteCount: 475)
        ])
    }

    @Test("Live settings use the active scenario and identical settings enqueue no work")
    func liveSettingsKeepPendingScenarioSeparate() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        simulation.draft.orbitAltitude = 315
        controller.clearEvents()

        #expect(controller.events.isEmpty)

        simulation.settings.timeScale = 2
        let currentSettings = simulation.settings
        simulation.settings = currentSettings
        simulation.settings.timeScale = 2

        #expect(controller.events == [.settings(currentSettings, .defaults)])
        #expect(simulation.active == .defaults)
        #expect(simulation.hasPendingChanges)
    }

    @Test("Reset Defaults preserves the active scenario, playback and stats visibility",
          arguments: [true, false])
    func defaultsDoNotRestartOrChangePlayback(isPaused: Bool) {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        simulation.draft.satelliteCount = 450
        simulation.draft.orbitAltitude = 310
        simulation.resetSimulation()
        let activeScenario = simulation.active

        simulation.isPaused = isPaused
        simulation.settings.timeScale = 4
        simulation.settings.showSatellites = false
        simulation.draft.orbitAltitude = 320
        simulation.isCameraEnabled = false
        simulation.showStats = false
        controller.clearEvents()

        simulation.resetSettingsToDefaults()

        #expect(simulation.settings == .defaults)
        #expect(simulation.draft == .defaults)
        #expect(simulation.active == activeScenario)
        #expect(simulation.hasPendingChanges)
        #expect(simulation.isPaused == isPaused)
        #expect(controller.isPaused == isPaused)
        #expect(simulation.isCameraEnabled)
        #expect(!simulation.showStats)
        #expect(controller.events == [.settings(.defaults, activeScenario)])
    }

    @Test("Assigning identical settings does not notify observing views")
    func identicalSettingsDoNotInvalidateObservers() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        let notifications = Mutex(0)
        withObservationTracking {
            _ = simulation.settings
        } onChange: {
            notifications.withLock { $0 += 1 }
        }

        let unchanged = simulation.settings
        simulation.settings = unchanged
        #expect(notifications.withLock { $0 } == 0)

        var changed = unchanged
        changed.timeScale = 2
        simulation.settings = changed
        #expect(notifications.withLock { $0 } == 1)
        #expect(simulation.settings == changed)
    }

    @Test("Telemetry publishes changed counts once and ignores duplicate callbacks")
    func duplicateTelemetryDoesNotInvalidateObservers() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        let notifications = Mutex(0)
        withObservationTracking {
            _ = simulation.telemetry.stats
        } onChange: {
            notifications.withLock { $0 += 1 }
        }

        controller.emitStats(SimStats())
        #expect(notifications.withLock { $0 } == 0)

        let first = SimStats(debris: 7, satellites: 299)
        controller.emitStats(first)
        #expect(simulation.telemetry.stats == first)
        #expect(notifications.withLock { $0 } == 1)

        // Observation tracking is one-shot; subscribe again before testing the duplicate.
        withObservationTracking {
            _ = simulation.telemetry.stats
        } onChange: {
            notifications.withLock { $0 += 1 }
        }
        controller.emitStats(first)
        #expect(notifications.withLock { $0 } == 1)

        let next = SimStats(debris: 14, satellites: 298)
        controller.emitStats(next)
        #expect(simulation.telemetry.stats == next)
        #expect(notifications.withLock { $0 } == 2)
    }

    @Test("Playback controls and direct bindings reach the scene controller")
    func playbackAndDetonationAreForwarded() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        controller.clearEvents()

        simulation.resumeSimulation()
        simulation.pauseSimulation()
        simulation.isPaused = false
        simulation.triggerDetonation()

        #expect(controller.events == [
            .playback(paused: false), .playback(paused: true),
            .playback(paused: false), .detonate
        ])
    }

    @Test("Camera gestures preserve their deltas and closing settings clears the offset")
    func cameraControlsAreForwarded() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        controller.clearEvents()

        simulation.resetCamera()
        simulation.rotateCamera(deltaX: -0.2, deltaY: 0.3)
        simulation.zoomCamera(scaleFactor: 1.5)
        simulation.setSettingsPanel(isOpen: true, ratio: 0.125, aspectRatio: 1.5)
        simulation.setSettingsPanel(isOpen: false, ratio: 0.125, aspectRatio: 1.5)

        #expect(controller.events == [
            .resetCamera,
            .rotate(deltaX: -0.2, deltaY: 0.3),
            .zoom(scaleFactor: 1.5),
            .cameraOffset(ratio: 0.125, aspectRatio: 1.5),
            .cameraOffset(ratio: 0, aspectRatio: 1.5)
        ])
    }

    @Test("Scene attachment forwards the supplied view unchanged")
    func viewAttachmentIsForwarded() {
        let controller = SimulationControllerSpy()
        let simulation = Simulation(controller: controller)
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)

        simulation.attachToView(view)

        #expect(controller.attachedView === view)
    }

    @Test("The controller callback does not retain a discarded simulation")
    func statsCallbackDoesNotKeepSimulationAlive() {
        let controller = SimulationControllerSpy()
        var simulation: Simulation? = Simulation(controller: controller)
        let releasedSimulation = { [weak simulation] in simulation }

        simulation = nil

        #expect(releasedSimulation() == nil)
        controller.emitStats(SimStats(debris: 7, satellites: 299))
    }
}
