//
//  DebrisMesh.swift
//  Cascade
//

import simd

enum DebrisMesh {

    static let verticesPerFragment = 4
    static let indicesPerFragment = 12

    static let corners: [SIMD3<Float>] = [
        SIMD3( 0.000,  1.125,  0.000),
        SIMD3( 1.125, -1.125,  0.650),
        SIMD3(-1.125, -1.125,  0.650),
        SIMD3( 0.000, -1.125, -1.299)
    ]

    static let faceIndices: [UInt32] = [0, 2, 1, 0, 3, 2, 0, 1, 3, 1, 2, 3]
}

typealias DebrisVertex = SIMD3<Float>
