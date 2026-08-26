//
//  FrameBuffer.swift
//  Cascade
//

final class FrameBuffer: @unchecked Sendable {
    var vertices: ContiguousArray<DebrisVertex>

    private(set) var activeVertexCount = 0

    private(set) var dirtyVertexCount = 0

    private var lastWrittenCount = 0

    init(maxDebris: Int) {
        vertices = ContiguousArray(repeating: .zero, count: maxDebris * DebrisMesh.verticesPerFragment)
    }

    func prepare(activeCount: Int) {
        let activeVerts = activeCount * DebrisMesh.verticesPerFragment
        activeVertexCount = activeVerts
        dirtyVertexCount = max(activeVerts, lastWrittenCount)
        lastWrittenCount = activeVerts
    }
}
