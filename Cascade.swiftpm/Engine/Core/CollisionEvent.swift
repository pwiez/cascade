//
//  CollisionEvent.swift
//  Cascade
//

import simd

struct CollisionEvent: Sendable {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
}
