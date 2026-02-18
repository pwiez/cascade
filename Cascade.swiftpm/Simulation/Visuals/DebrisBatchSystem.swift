import RealityKit
import Foundation
import simd

@MainActor
class DebrisBatchSystem {
    public let entity: ModelEntity
    public var meshResource: MeshResource
    
    private let maxDebris: Int
    
    private var allPositions: [SIMD3<Float>]
    private var allNormals: [SIMD3<Float>]
    private var allIndices: [UInt32]
    
    private let localVerts: [SIMD3<Float>] = [
        SIMD3(0, 0.5, 0),
        SIMD3(0.5, -0.5, 0.289),
        SIMD3(-0.5, -0.5, 0.289),
        SIMD3(0, -0.5, -0.577)
    ]
    
    init(maxDebris: Int, material: Material) {
        self.maxDebris = maxDebris
        let totalVerts = maxDebris * 4
        let totalIndices = maxDebris * 12
        
        self.allPositions = Array(repeating: .zero, count: totalVerts)
        self.allNormals = Array(repeating: [0, 1, 0], count: totalVerts)
        self.allIndices = Array(repeating: 0, count: totalIndices)
        
        let baseIndices: [UInt32] = [0, 1, 2, 0, 2, 3, 0, 3, 1, 1, 3, 2]
        
        for i in 0..<maxDebris {
            let vertOffset = UInt32(i * 4)
            let indexOffset = i * 12
            
            for j in 0..<12 {
                self.allIndices[indexOffset + j] = vertOffset + baseIndices[j]
            }
        }
        
        var descriptor = MeshDescriptor(name: "MegaDebrisMesh")
        descriptor.positions = MeshBuffer(allPositions)
        descriptor.normals = MeshBuffer(allNormals)
        descriptor.primitives = .triangles(allIndices)
        
        self.meshResource = try! MeshResource.generate(from: [descriptor])
        self.entity = ModelEntity(mesh: meshResource, materials: [material])
    }
    
    func update(activeCount: Int,
                posX: [Float], posY: [Float], posZ: [Float],
                scale: Float) {
        
        allPositions.withUnsafeMutableBufferPointer { vPtr in
            for i in 0..<activeCount {
                let pos = SIMD3<Float>(posX[i], posY[i], posZ[i])
                let base = i * 4
                
                vPtr[base + 0] = pos + (localVerts[0] * scale)
                vPtr[base + 1] = pos + (localVerts[1] * scale)
                vPtr[base + 2] = pos + (localVerts[2] * scale)
                vPtr[base + 3] = pos + (localVerts[3] * scale)
            }
            
            if activeCount < maxDebris {
                let start = activeCount * 4
                if start < vPtr.count {
                     for k in start..<vPtr.count { vPtr[k] = .zero }
                }
            }
        }
        
        var descriptor = MeshDescriptor(name: "MegaDebrisMesh")
        descriptor.positions = MeshBuffer(allPositions)
        descriptor.normals = MeshBuffer(allNormals)
        descriptor.primitives = .triangles(allIndices)
        
        if let newMesh = try? MeshResource.generate(from: [descriptor]) {
            try? self.meshResource.replace(with: newMesh.contents)
        }
    }
    
    func updateMaterial(_ newMaterial: Material) {
        if var model = entity.model {
            model.materials = [newMaterial]
            entity.model = model
        }
    }
}
