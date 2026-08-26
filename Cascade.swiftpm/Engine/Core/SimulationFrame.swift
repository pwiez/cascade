//
//  SimulationFrame.swift
//  Cascade
//

/// The result of one solver step, handed back to the main actor.
///
/// `@unchecked Sendable` covers `vertexBuffer`; see ``FrameBuffer`` for the
/// invariant that makes it safe.
struct SimulationFrame: @unchecked Sendable {
    let debrisCount: Int
    let vertexBuffer: FrameBuffer
    let killedSatelliteIndices: [Int]
}
