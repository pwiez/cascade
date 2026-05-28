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
    private let backend: any DebrisRenderBackend

    var entity: ModelEntity { backend.entity }

    init(maxDebris: Int, color: UIColor) {
        if #available(iOS 18, *) {
            backend = LowLevelMeshBackend(maxDebris: maxDebris, color: color)
        } else {
            backend = MeshDescriptorBackend(maxDebris: maxDebris, color: color)
        }
    }

    func commitVertices(from buffer: FrameBuffer) { backend.commitVertices(from: buffer) }
    func clear() { backend.clear() }
    func updateColor(_ newColor: UIColor) { backend.updateColor(newColor) }
}

@MainActor
private protocol DebrisRenderBackend {
    var entity: ModelEntity { get }
    func commitVertices(from buffer: FrameBuffer)
    func clear()
    func updateColor(_ newColor: UIColor)
}

@available(iOS 18, *)
private final class LowLevelMeshBackend: DebrisRenderBackend {
    let entity: ModelEntity
    private var meshes: [LowLevelMesh]
    private var meshResources: [MeshResource]
    private var currentMeshIndex: Int = 0
    private var material: UnlitMaterial

    private let maxDebris: Int
    private static let ringSize = 3

    init(maxDebris: Int, color: UIColor) {
        self.maxDebris = maxDebris
        let totalVerts = maxDebris * 4
        let totalIndices = maxDebris * 12

        var desc = LowLevelMesh.Descriptor()
        desc.vertexCapacity = totalVerts
        desc.indexCapacity = totalIndices
        desc.vertexAttributes = [
            .init(semantic: .position, format: .float3, offset: 0)
        ]
        desc.vertexLayouts = [.init(bufferIndex: 0, bufferStride: 16)]
        desc.indexType = .uint32

        let baseIndices: [UInt32] = [0, 2, 1, 0, 3, 2, 0, 1, 3, 1, 2, 3]
        let bounds = BoundingBox(min: [-1000, -1000, -1000], max: [1000, 1000, 1000])

        var builtMeshes: [LowLevelMesh] = []
        builtMeshes.reserveCapacity(Self.ringSize)
        for _ in 0..<Self.ringSize {
            let mesh = try! LowLevelMesh(descriptor: desc)
            mesh.withUnsafeMutableIndices { buffer in
                let indices = buffer.bindMemory(to: UInt32.self)
                for i in 0..<maxDebris {
                    let vOff = UInt32(i * 4)
                    let iOff = i * 12
                    for j in 0..<12 { indices[iOff + j] = vOff + baseIndices[j] }
                }
            }
            mesh.parts.replaceAll([LowLevelMesh.Part(indexCount: totalIndices, topology: .triangle, bounds: bounds)])
            builtMeshes.append(mesh)
        }

        self.meshes = builtMeshes
        self.meshResources = builtMeshes.map { try! MeshResource(from: $0) }

        self.material = UnlitMaterial(color: color)
        self.entity = ModelEntity(mesh: meshResources[0], materials: [self.material])
    }

    func commitVertices(from buffer: FrameBuffer) {
        let backIndex = (currentMeshIndex + 1) % Self.ringSize
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
        let backIndex = (currentMeshIndex + 1) % Self.ringSize
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

private final class MeshDescriptorBackend: DebrisRenderBackend {
    let entity: ModelEntity
    private var material: UnlitMaterial

    private let maxDebris: Int
    private let allIndices: [UInt32]

    init(maxDebris: Int, color: UIColor) {
        self.maxDebris = maxDebris

        let baseIndices: [UInt32] = [0, 2, 1, 0, 3, 2, 0, 1, 3, 1, 2, 3]
        var indices: [UInt32] = []
        indices.reserveCapacity(maxDebris * 12)
        for i in 0..<maxDebris {
            let vOff = UInt32(i * 4)
            for j in baseIndices { indices.append(vOff + j) }
        }
        self.allIndices = indices

        self.material = UnlitMaterial(color: color)
        self.entity = ModelEntity(mesh: Self.emptyMesh(), materials: [self.material])
    }

    func commitVertices(from buffer: FrameBuffer) {
        let count = buffer.dirtyVertexCount
        guard count >= 4 else { clear(); return }

        let indexCount = (count / 4) * 12
        var desc = MeshDescriptor()
        desc.positions = MeshBuffers.Positions(Array(buffer.vertices[0..<count]))
        desc.primitives = .triangles(Array(allIndices[0..<indexCount]))

        if let resource = try? MeshResource.generate(from: [desc]) {
            entity.model?.mesh = resource
        }
    }

    func clear() {
        entity.model?.mesh = Self.emptyMesh()
    }

    func updateColor(_ newColor: UIColor) {
        self.material = UnlitMaterial(color: newColor)
        if var model = entity.model {
            model.materials = [self.material]
            entity.model = model
        }
    }

    private static func emptyMesh() -> MeshResource {
        var desc = MeshDescriptor()
        desc.positions = MeshBuffers.Positions([.zero, .zero, .zero])
        desc.primitives = .triangles([0, 1, 2])
        return (try? MeshResource.generate(from: [desc])) ?? .generateBox(size: 0.0001)
    }
}
