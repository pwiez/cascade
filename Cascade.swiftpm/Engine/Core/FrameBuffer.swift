//
//  FrameBuffer.swift
//  Cascade
//

/// A frame owns a value snapshot; copy-on-write storage lets the solver reuse its
/// buffers without mutating vertices still held by a consumer.
struct FrameBuffer: Sendable {
    var vertices: ContiguousArray<DebrisVertex>

    private(set) var activeVertexCount = 0

    init(maxDebris: Int) {
        vertices = ContiguousArray(repeating: .zero, count: maxDebris * DebrisMesh.verticesPerFragment)
    }

    mutating func prepare(activeCount: Int) {
        precondition(activeCount >= 0 && activeCount <= vertices.count / DebrisMesh.verticesPerFragment,
                     "Active fragments must fit within the allocated vertex buffer.")
        activeVertexCount = activeCount * DebrisMesh.verticesPerFragment
    }
}
