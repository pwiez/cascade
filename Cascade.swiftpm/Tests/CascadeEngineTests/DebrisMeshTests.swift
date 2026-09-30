//
//  DebrisMeshTests.swift
//  CascadeEngineTests
//

import Testing
import simd
@testable import CascadeEngine

@Suite("Debris mesh geometry")
struct DebrisMeshTests {
    private struct Edge: Hashable {
        let from: Int
        let to: Int
    }

    @Test("Fragments form a closed mesh with outward-facing, nondegenerate triangles")
    func closedOutwardFacingMesh() throws {
        let vertices = DebrisMesh.corners
        let indices = DebrisMesh.faceIndices.map(Int.init)
        try #require(!vertices.isEmpty && !indices.isEmpty)
        try #require(indices.count.isMultiple(of: 3))
        try #require(indices.allSatisfy { vertices.indices.contains($0) })
        let center = vertices.reduce(SIMD3<Float>.zero, +) / Float(vertices.count)
        var directedEdges: [Edge: Int] = [:]

        for start in stride(from: 0, to: indices.count, by: 3) {
            let triangle = Array(indices[start..<(start + 3)])
            let first = vertices[triangle[0]]
            let second = vertices[triangle[1]]
            let third = vertices[triangle[2]]
            let normal = cross(second - first, third - first)
            let faceCenter = (first + second + third) / 3
            #expect(dot(normal, faceCenter - center) > 0)

            for corner in 0..<3 {
                let edge = Edge(from: triangle[corner], to: triangle[(corner + 1) % 3])
                directedEdges[edge, default: 0] += 1
            }
        }

        for (edge, count) in directedEdges {
            #expect(count == 1)
            #expect(directedEdges[Edge(from: edge.to, to: edge.from)] == 1)
        }
        #expect(Set(indices) == Set(vertices.indices))
    }
}
