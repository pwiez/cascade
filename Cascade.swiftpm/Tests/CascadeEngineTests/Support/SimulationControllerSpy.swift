//
//  SimulationControllerSpy.swift
//  CascadeEngineTests
//

import RealityKit
@testable import CascadeEngine

@MainActor
final class SimulationControllerSpy: SimulationControlling {
    enum Event: Equatable {
        case playback(paused: Bool)
        case settings(SimSettings, Scenario)
        case reset(satelliteCount: Int)
        case detonate
        case resetCamera
        case rotate(deltaX: Float, deltaY: Float)
        case zoom(scaleFactor: Float)
        case cameraOffset(ratio: Float, aspectRatio: Float)
    }

    var onStatsChange: ((SimStats) -> Void)?
    var isPaused = true {
        didSet { events.append(.playback(paused: isPaused)) }
    }

    private(set) var events: [Event] = []
    private(set) weak var attachedView: ARView?

    func clearEvents() {
        events.removeAll(keepingCapacity: true)
    }

    func emitStats(_ stats: SimStats) {
        onStatsChange?(stats)
    }

    func queueCommand(_ command: EngineCommand) {
        switch command {
        case .updateSettings(let settings): events.append(.settings(settings.sim, settings.scenario))
        case .reset(let count): events.append(.reset(satelliteCount: count))
        case .detonate: events.append(.detonate)
        }
    }

    func attach(to view: ARView) {
        attachedView = view
    }

    func resetCamera() {
        events.append(.resetCamera)
    }

    func rotateCamera(deltaX: Float, deltaY: Float) {
        events.append(.rotate(deltaX: deltaX, deltaY: deltaY))
    }

    func zoomCamera(scaleFactor: Float) {
        events.append(.zoom(scaleFactor: scaleFactor))
    }

    func setCameraOffset(ratio: Float, aspectRatio: Float) {
        events.append(.cameraOffset(ratio: ratio, aspectRatio: aspectRatio))
    }
}
