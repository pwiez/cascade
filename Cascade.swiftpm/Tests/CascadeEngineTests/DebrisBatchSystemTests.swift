//
//  DebrisBatchSystemTests.swift
//  CascadeEngineTests
//

import RealityKit
import Testing
import UIKit
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

    @Test("Every fragment has four distinct triangular faces within its own vertices")
    func fragmentTopologyIsSelfContained() throws {
        let batch = DebrisBatchSystem(maxDebris: 8, color: .white)
        let mesh = try #require(batch.entity.model?.mesh.lowLevelMesh)

        mesh.withUnsafeIndices { bytes in
            let indices = bytes.bindMemory(to: UInt32.self)
            for fragment in 0..<8 {
                let vertexStart = UInt32(fragment * DebrisMesh.verticesPerFragment)
                let vertexEnd = vertexStart + UInt32(DebrisMesh.verticesPerFragment)
                let indexStart = fragment * DebrisMesh.indicesPerFragment
                var faces = Set<Set<UInt32>>()
                for face in 0..<4 {
                    let start = indexStart + face * 3
                    let triangle = Set(indices[start..<(start + 3)])
                    #expect(triangle.count == 3)
                    #expect(triangle.allSatisfy { $0 >= vertexStart && $0 < vertexEnd })
                    faces.insert(triangle)
                }
                #expect(faces.count == 4)
            }
        }
    }

    @Test("Color changes survive frame rotation and clearing without altering visibility")
    func colorAndVisibilitySurviveMeshUpdates() throws {
        let batch = DebrisBatchSystem(maxDebris: 2, color: .red)
        let originalMaterial = try #require(batch.entity.model?.materials.first as? UnlitMaterial)
        try expectColor(originalMaterial.color.tint, red: 1, green: 0, blue: 0)
        batch.entity.isEnabled = false
        batch.updateColor(.cyan)

        var frame = FrameBuffer(maxDebris: 2)
        frame.prepare(activeCount: 1)
        for _ in 0..<5 {
            batch.commitVertices(from: frame)
            let material = try #require(batch.entity.model?.materials.first as? UnlitMaterial)
            try expectColor(material.color.tint, red: 0, green: 1, blue: 1)
            #expect(!batch.entity.isEnabled)
        }
        batch.clear()
        let material = try #require(batch.entity.model?.materials.first as? UnlitMaterial)
        try expectColor(material.color.tint, red: 0, green: 1, blue: 1)
        #expect(!batch.entity.isEnabled)
    }
}
