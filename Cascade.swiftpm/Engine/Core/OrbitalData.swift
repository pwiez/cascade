//
//  OrbitalData.swift
//  Cascade
//

import RealityKit
import simd

/// Velocity carried alongside a satellite entity.
///
/// Satellites are real RealityKit entities (there are only a few hundred, and
/// they need individual materials and visibility), so their integration state
/// rides on the entity as a component. Debris takes the opposite approach — see
/// ``DebrisPool`` — because thousands of entities would not hold framerate.
struct OrbitalData: Component {
    var velocity: SIMD3<Float>
}
