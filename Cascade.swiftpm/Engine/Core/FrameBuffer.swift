//
//  FrameBuffer.swift
//  Cascade
//

/// One frame's worth of debris vertices, written by the solver and read by the
/// renderer.
///
/// `@unchecked Sendable` is load-bearing rather than lazy: `SceneController`
/// keeps exactly one solver step in flight at a time, and the solver alternates
/// between two of these, so the buffer being handed to the main actor is never
/// the one being written. That invariant lives in `SceneController.runSimulationFrame`.
final class FrameBuffer: @unchecked Sendable {
    var vertices: ContiguousArray<DebrisVertex>

    /// Vertices belonging to live debris this frame.
    private(set) var activeVertexCount = 0

    /// Vertices that must be uploaded — the live ones, plus whatever the previous
    /// frame left behind that now needs zeroing so dead debris doesn't smear.
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
