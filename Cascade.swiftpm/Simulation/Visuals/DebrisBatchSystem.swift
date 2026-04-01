//
//  DebrisBatchSystem.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import RealityKit
import Foundation
import simd
import UIKit

@MainActor
class DebrisBatchSystem {
    public let entity: ModelEntity
    private var meshes: [LowLevelMesh]
    private var meshResources: [MeshResource]
    private var currentMeshIndex: Int = 0
    private var material: UnlitMaterial

    private let maxDebris: Int

    init(maxDebris: Int, color: UIColor) {
        self.maxDebris = maxDebris
        let totalVerts = maxDebris * 4
        let totalIndices = maxDebris * 12

        var desc = LowLevelMesh.Descriptor()
        desc.vertexCapacity = totalVerts
        desc.indexCapacity = totalIndices
        desc.vertexAttributes = [
            .init(semantic: .position, format: .float3, offset: 0),
            .init(semantic: .normal, format: .float3, offset: 16)
        ]
        desc.vertexLayouts = [.init(bufferIndex: 0, bufferStride: 32)]
        desc.indexType = .uint32

        let mesh0 = try! LowLevelMesh(descriptor: desc)
        let mesh1 = try! LowLevelMesh(descriptor: desc)

        let baseIndices: [UInt32] = [0, 2, 1, 0, 3, 2, 0, 1, 3, 1, 2, 3]
        let bounds = BoundingBox(min: [-1000, -1000, -1000], max: [1000, 1000, 1000])

        for mesh in [mesh0, mesh1] {
            mesh.withUnsafeMutableIndices { buffer in
                let indices = buffer.bindMemory(to: UInt32.self)
                for i in 0..<maxDebris {
                    let vOff = UInt32(i * 4)
                    let iOff = i * 12
                    for j in 0..<12 { indices[iOff + j] = vOff + baseIndices[j] }
                }
            }
            mesh.parts.replaceAll([LowLevelMesh.Part(indexCount: totalIndices, topology: .triangle, bounds: bounds)])
        }

        self.meshes = [mesh0, mesh1]
        self.meshResources = [
            try! MeshResource(from: mesh0),
            try! MeshResource(from: mesh1)
        ]

        self.material = UnlitMaterial(color: color)
        self.entity = ModelEntity(mesh: meshResources[0], materials: [self.material])
    }

    func commitVertices(from buffer: FrameBuffer) {
        let backIndex = 1 - currentMeshIndex
        let vertexStride = MemoryLayout<DebrisVertex>.stride

        meshes[backIndex].withUnsafeMutableBytes(bufferIndex: 0) { rawBuffer in
            buffer.vertices.withUnsafeBufferPointer { src in
                let byteCount = buffer.dirtyVertexCount * vertexStride
                if byteCount > 0 {
                    memcpy(rawBuffer.baseAddress!, src.baseAddress!, byteCount)
                }
            }
        }

        entity.model?.mesh = meshResources[backIndex]
        currentMeshIndex = backIndex
    }

    func clear() {
        let backIndex = 1 - currentMeshIndex
        meshes[backIndex].withUnsafeMutableBytes(bufferIndex: 0) { buffer in
            memset(buffer.baseAddress!, 0, buffer.count)
        }
        entity.model?.mesh = meshResources[backIndex]
        currentMeshIndex = backIndex
    }

    func updateColor(_ newColor: UIColor) {
        self.material = UnlitMaterial(color: newColor)
        if var model = entity.model {
            model.materials = [self.material]
            entity.model = model
        }
    }
}
