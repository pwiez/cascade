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

    private let buffers: [(mesh: LowLevelMesh, resource: MeshResource)]
    private var currentMeshIndex = 0

    init(maxDebris: Int, color: UIColor) {
        let totalVertices = maxDebris * DebrisMesh.verticesPerFragment
        let totalIndices = maxDebris * DebrisMesh.indicesPerFragment

        var descriptor = LowLevelMesh.Descriptor()
        descriptor.vertexCapacity = totalVertices
        descriptor.indexCapacity = totalIndices
        descriptor.vertexAttributes = [.init(semantic: .position, format: .float3, offset: 0)]
        descriptor.vertexLayouts = [.init(bufferIndex: 0, bufferStride: MemoryLayout<DebrisVertex>.stride)]
        descriptor.indexType = .uint32

        let bounds = BoundingBox(min: [-1000, -1000, -1000], max: [1000, 1000, 1000])

        var built: [(mesh: LowLevelMesh, resource: MeshResource)] = []
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
                LowLevelMesh.Part(indexCount: 0, topology: .triangle, bounds: bounds)
            ])
            // Keep each resource paired with its writable mesh even if allocation fails.
            guard let resource = try? MeshResource(from: mesh) else { continue }
            built.append((mesh, resource))
        }

        buffers = built

        entity = ModelEntity()
        if let first = buffers.first {
            entity.model = ModelComponent(mesh: first.resource, materials: [UnlitMaterial(color: color)])
        }
    }

    func commitVertices(from buffer: FrameBuffer) {
        guard !buffers.isEmpty else { return }
        let next = (currentMeshIndex + 1) % buffers.count
        let mesh = buffers[next].mesh
        precondition(buffer.activeVertexCount <= mesh.vertexCapacity)

        if buffer.activeVertexCount > 0 {
            mesh.withUnsafeMutableBytes(bufferIndex: 0) { destination in
                buffer.vertices.withUnsafeBufferPointer { source in
                    let byteCount = buffer.activeVertexCount * MemoryLayout<DebrisVertex>.stride
                    guard let destinationBase = destination.baseAddress,
                          let sourceBase = source.baseAddress else { return }
                    memcpy(destinationBase, sourceBase, byteCount)
                }
            }
        }

        // Draw only the active prefix; older vertices in a reused mesh remain outside the draw range.
        mesh.parts[0].indexCount = buffer.activeVertexCount / DebrisMesh.verticesPerFragment
            * DebrisMesh.indicesPerFragment
        entity.model?.mesh = buffers[next].resource
        currentMeshIndex = next
    }

    func clear() {
        guard !buffers.isEmpty else { return }
        let next = (currentMeshIndex + 1) % buffers.count

        buffers[next].mesh.parts[0].indexCount = 0
        entity.model?.mesh = buffers[next].resource
        currentMeshIndex = next
    }

    func updateColor(_ newColor: UIColor) {
        entity.model?.materials = [UnlitMaterial(color: newColor)]
    }
}
