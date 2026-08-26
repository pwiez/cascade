//
//  SimulationFrame.swift
//  Cascade
//

struct SimulationFrame: @unchecked Sendable {
    let debrisCount: Int
    let vertexBuffer: FrameBuffer
    let killedSatelliteIndices: [Int]
}
