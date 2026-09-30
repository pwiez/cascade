//
//  DebrisBatchSystemTests.swift
//  CascadeEngineTests
//

import RealityKit
import Testing
@testable import CascadeEngine

@Suite("DebrisBatchSystem")
@MainActor
struct DebrisBatchSystemTests {

    @Test("A new batch has no drawable fragments")
    func startsEmpty() throws {
        let batch = DebrisBatchSystem(maxDebris: 8, color: .white)
        let mesh = try #require(batch.entity.model?.mesh.lowLevelMesh)

        #expect(mesh.parts[0].indexCount == 0)
    }

    @Test("Reused meshes draw only the current fragments after shrinking and growing")
    func reusingMeshesKeepsTheCurrentFrame() throws {
        let batch = DebrisBatchSystem(maxDebris: 8, color: .white)
        var frame = FrameBuffer(maxDebris: 8)

        for (step, count) in [8, 8, 8, 2, 1, 0, 5, 3, 8, 0].enumerated() {
            frame.prepare(activeCount: count)
            for index in 0..<frame.activeVertexCount {
                frame.vertices[index] = SIMD3(Float(step), Float(index), 1)
            }
            batch.commitVertices(from: frame)

            let mesh = try #require(batch.entity.model?.mesh.lowLevelMesh)
            #expect(mesh.parts[0].indexCount == count * DebrisMesh.indicesPerFragment)
            mesh.withUnsafeBytes(bufferIndex: 0) { bytes in
                let vertices = bytes.bindMemory(to: DebrisVertex.self)
                for index in 0..<frame.activeVertexCount {
                    #expect(vertices[index] == frame.vertices[index])
                }
            }
        }
    }

    @Test("Clearing and resuming never revives an older frame")
    func clearThenResume() throws {
        let batch = DebrisBatchSystem(maxDebris: 8, color: .white)
        var frame = FrameBuffer(maxDebris: 8)
        frame.prepare(activeCount: 8)
        for index in 0..<frame.activeVertexCount {
            frame.vertices[index] = SIMD3(Float(index), 1, 2)
        }
        for _ in 0..<4 { batch.commitVertices(from: frame) }

        for _ in 0..<5 {
            batch.clear()
            let cleared = try #require(batch.entity.model?.mesh.lowLevelMesh)
            #expect(cleared.parts[0].indexCount == 0)

            frame.prepare(activeCount: 1)
            batch.commitVertices(from: frame)
            let resumed = try #require(batch.entity.model?.mesh.lowLevelMesh)
            #expect(resumed.parts[0].indexCount == DebrisMesh.indicesPerFragment)
        }
    }
}
