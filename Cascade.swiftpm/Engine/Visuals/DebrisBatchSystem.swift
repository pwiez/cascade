//
//  DebrisBatchSystem.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import RealityKit
import UIKit

@MainActor
final class DebrisBatchSystem {

    let entity: ModelEntity

    private static let ringSize = 3

    private let meshes: [LowLevelMesh]
    private let meshResources: [MeshResource]
    private var currentMeshIndex = 0
    private var material: UnlitMaterial

    init(maxDebris: Int, color: UIColor) {
        let totalVertices = maxDebris * DebrisMesh.verticesPerFragment
        let totalIndices = maxDebris * DebrisMesh.indicesPerFragment

        var descriptor = LowLevelMesh.Descriptor()
        descriptor.vertexCapacity = totalVertices
        descriptor.indexCapacity = totalIndices
        descriptor.vertexAttributes = [.init(semantic: .position, format: .float3, offset: 0)]
        descriptor.vertexLayouts = [.init(bufferIndex: 0, bufferStride: 16)]
        descriptor.indexType = .uint32

        let bounds = BoundingBox(min: [-1000, -1000, -1000], max: [1000, 1000, 1000])

        var built: [LowLevelMesh] = []
        built.reserveCapacity(Self.ringSize)

        for _ in 0..<Self.ringSize {
            guard let mesh = try? LowLevelMesh(descriptor: descriptor) else { continue }
            mesh.withUnsafeMutableIndices { buffer in
                let indices = buffer.bindMemory(to: UInt32.self)
                for fragment in 0..<maxDebris {
                    let vertexOffset = UInt32(fragment * DebrisMesh.verticesPerFragment)
                    let indexOffset = fragment * DebrisMesh.indicesPerFragment
                    for corner in 0..<DebrisMesh.indicesPerFragment {
                        indices[indexOffset + corner] = vertexOffset + DebrisMesh.faceIndices[corner]
                    }
                }
            }
            mesh.parts.replaceAll([
                LowLevelMesh.Part(indexCount: totalIndices, topology: .triangle, bounds: bounds)
            ])
            built.append(mesh)
        }

        meshes = built
        meshResources = built.compactMap { try? MeshResource(from: $0) }
        material = UnlitMaterial(color: color)

        entity = ModelEntity()
        if let first = meshResources.first {
            entity.model = ModelComponent(mesh: first, materials: [material])
        }
    }

    func commitVertices(from buffer: FrameBuffer) {
        guard !meshes.isEmpty else { return }
        let next = (currentMeshIndex + 1) % meshes.count

        meshes[next].withUnsafeMutableBytes(bufferIndex: 0) { destination in
            buffer.vertices.withUnsafeBufferPointer { source in
                let byteCount = buffer.dirtyVertexCount * MemoryLayout<DebrisVertex>.stride
                guard byteCount > 0,
                      let destinationBase = destination.baseAddress,
                      let sourceBase = source.baseAddress else { return }
                memcpy(destinationBase, sourceBase, min(byteCount, destination.count))
            }
        }

        entity.model?.mesh = meshResources[next]
        currentMeshIndex = next
    }

    func clear() {
        guard !meshes.isEmpty else { return }
        let next = (currentMeshIndex + 1) % meshes.count

        meshes[next].withUnsafeMutableBytes(bufferIndex: 0) { buffer in
            guard let base = buffer.baseAddress else { return }
            memset(base, 0, buffer.count)
        }

        entity.model?.mesh = meshResources[next]
        currentMeshIndex = next
    }

    func updateColor(_ newColor: UIColor) {
        material = UnlitMaterial(color: newColor)
        entity.model?.materials = [material]
    }
}
