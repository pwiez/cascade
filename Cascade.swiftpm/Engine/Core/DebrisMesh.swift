//
//  DebrisMesh.swift
//  Cascade
//

import simd

/// The tetrahedron every debris fragment is drawn as.
///
/// All fragments share one mesh in one draw call — `DebrisBatchSystem` writes
/// every fragment's four transformed corners into a single vertex buffer — so
/// the shape is a set of constants rather than a `MeshResource`.
enum DebrisMesh {

    static let verticesPerFragment = 4
    static let indicesPerFragment = 12

    /// Corner offsets from a fragment's centre, before scale and spin.
    static let corners: [SIMD3<Float>] = [
        SIMD3( 0.000,  1.125,  0.000),
        SIMD3( 1.125, -1.125,  0.650),
        SIMD3(-1.125, -1.125,  0.650),
        SIMD3( 0.000, -1.125, -1.299)
    ]

    /// Winding for the four faces, as offsets into one fragment's corners.
    static let faceIndices: [UInt32] = [0, 2, 1, 0, 3, 2, 0, 1, 3, 1, 2, 3]
}

/// One corner of one debris fragment, in world space.
typealias DebrisVertex = SIMD3<Float>
