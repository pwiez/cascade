//
//  MeshGeneration.swift
//  Cascade
//
//  Created by Pedro Wiezel on 17/02/26.
//

import RealityKit
import simd

extension MeshResource {
    static func generateDebrisTetrahedron(size: Float) -> MeshResource {
        
        let s = size
        let h = size * 0.866 
        
        let yTop = h * 0.5
        let yBot = -h * 0.5
        
        let p0 = SIMD3<Float>(0, yTop, 0)                   
        let p1 = SIMD3<Float>(s * 0.5, yBot, s * 0.289)     
        let p2 = SIMD3<Float>(-s * 0.5, yBot, s * 0.289)    
        let p3 = SIMD3<Float>(0, yBot, -s * 0.577)          
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        func addFace(_ v1: SIMD3<Float>, _ v2: SIMD3<Float>, _ v3: SIMD3<Float>) {
            let startIndex = UInt32(positions.count)
            positions.append(contentsOf: [v1, v2, v3])
            indices.append(contentsOf: [startIndex, startIndex + 1, startIndex + 2])
            let n = normalize(cross(v2 - v1, v3 - v1))
            normals.append(contentsOf: [n, n, n])
        }
        
        addFace(p0, p2, p1) 
        addFace(p0, p3, p2) 
        addFace(p0, p1, p3) 
        addFace(p1, p2, p3) 
        
        var descriptor = MeshDescriptor(name: "DebrisTetra")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        
        return try! MeshResource.generate(from: [descriptor])
    }
}
