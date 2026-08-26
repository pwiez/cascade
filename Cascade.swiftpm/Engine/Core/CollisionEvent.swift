//
//  CollisionEvent.swift
//  Cascade
//

import simd

/// One object destroyed by an impact, and the momentum its fragments inherit.
struct CollisionEvent: Sendable {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
}
