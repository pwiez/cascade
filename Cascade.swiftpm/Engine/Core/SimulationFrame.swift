//
//  SimulationFrame.swift
//  Cascade
//

struct SimulationFrame: Sendable {
    let debrisCount: Int
    let vertexBuffer: FrameBuffer
    let killedSatelliteIndices: [Int]
}
