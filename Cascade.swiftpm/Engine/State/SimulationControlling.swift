//
//  SimulationControlling.swift
//  Cascade
//

import RealityKit

/// The scene operations used by UI state, independent of renderer construction.
@MainActor
protocol SimulationControlling: AnyObject {
    var onStatsChange: ((SimStats) -> Void)? { get set }
    var isPaused: Bool { get set }

    func queueCommand(_ command: EngineCommand)
    func attach(to view: ARView)

    func resetCamera()
    func rotateCamera(deltaX: Float, deltaY: Float)
    func zoomCamera(scaleFactor: Float)
    func setCameraOffset(ratio: Float, aspectRatio: Float)
}
