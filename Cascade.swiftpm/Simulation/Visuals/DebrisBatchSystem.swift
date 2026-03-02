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
    public var meshResource: MeshResource
    private let lowLevelMesh: LowLevelMesh
    private var material: UnlitMaterial
    
    private let maxDebris: Int
    
    private let localVerts: [SIMD3<Float>] = [
        SIMD3(0, 0.5, 0), SIMD3(0.5, -0.5, 0.289),
        SIMD3(-0.5, -0.5, 0.289), SIMD3(0, -0.5, -0.577)
    ]
    
    struct Vertex {
        var position: SIMD3<Float>
        var normal: SIMD3<Float>
    }
    
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
        
        self.lowLevelMesh = try! LowLevelMesh(descriptor: desc)
        
        lowLevelMesh.withUnsafeMutableIndices { buffer in
            let indices = buffer.bindMemory(to: UInt32.self)
            let baseIndices: [UInt32] = [0, 2, 1, 0, 3, 2, 0, 1, 3, 1, 2, 3]
            for i in 0..<maxDebris {
                let vOff = UInt32(i * 4)
                let iOff = i * 12
                for j in 0..<12 { indices[iOff + j] = vOff + baseIndices[j] }
            }
        }
        
        let bounds = BoundingBox(min: [-1000, -1000, -1000], max: [1000, 1000, 1000])
        lowLevelMesh.parts.replaceAll([LowLevelMesh.Part(indexCount: totalIndices, topology: .triangle, bounds: bounds)])
        
        self.meshResource = try! MeshResource(from: lowLevelMesh)
        self.material = UnlitMaterial(color: color)
        self.entity = ModelEntity(mesh: meshResource, materials: [self.material])
    }
    
    func update(activeCount: Int,
                posX: [Float], posY: [Float], posZ: [Float],
                rotAngle: [Float], rotAxisX: [Float], rotAxisY: [Float], rotAxisZ: [Float],
                scale: Float, spinEnabled: Bool) {
        
        let sv0 = localVerts[0] * scale
        let sv1 = localVerts[1] * scale
        let sv2 = localVerts[2] * scale
        let sv3 = localVerts[3] * scale
        let defaultNormal = SIMD3<Float>(0, 1, 0)
        
        lowLevelMesh.withUnsafeMutableBytes(bufferIndex: 0) { buffer in
            let vertices = buffer.bindMemory(to: Vertex.self)
            
            if spinEnabled {
                for i in 0..<activeCount {
                    let pos = SIMD3<Float>(posX[i], posY[i], posZ[i])
                    let axis = SIMD3<Float>(rotAxisX[i], rotAxisY[i], rotAxisZ[i])
                    let q = simd_quatf(angle: rotAngle[i], axis: axis)
                    
                    let base = i * 4
                    vertices[base + 0] = Vertex(position: pos + q.act(sv0), normal: defaultNormal)
                    vertices[base + 1] = Vertex(position: pos + q.act(sv1), normal: defaultNormal)
                    vertices[base + 2] = Vertex(position: pos + q.act(sv2), normal: defaultNormal)
                    vertices[base + 3] = Vertex(position: pos + q.act(sv3), normal: defaultNormal)
                }
            } else {
                for i in 0..<activeCount {
                    let pos = SIMD3<Float>(posX[i], posY[i], posZ[i])
                    
                    let base = i * 4
                    vertices[base + 0] = Vertex(position: pos + sv0, normal: defaultNormal)
                    vertices[base + 1] = Vertex(position: pos + sv1, normal: defaultNormal)
                    vertices[base + 2] = Vertex(position: pos + sv2, normal: defaultNormal)
                    vertices[base + 3] = Vertex(position: pos + sv3, normal: defaultNormal)
                }
            }
            
            if activeCount < maxDebris {
                let start = activeCount * 4
                let totalVerts = maxDebris * 4
                if start < totalVerts {
                    let zeroVert = Vertex(position: .zero, normal: defaultNormal)
                    for k in start..<totalVerts {
                        vertices[k] = zeroVert
                    }
                }
            }
        }
    }
    
    func updateColor(_ newColor: UIColor) {
        self.material = UnlitMaterial(color: newColor)
        if var model = entity.model {
            model.materials = [self.material]
            entity.model = model
        }
    }
}
