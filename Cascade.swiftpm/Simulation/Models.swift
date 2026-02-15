import Foundation
import RealityKit
import simd

enum BodyType { case leo, meo, geo, debris }

struct SpaceFact: Identifiable, Equatable {
    let id = UUID()
    let title, description, icon: String
}

struct CollisionEvent: Sendable {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
}

struct OrbitalData: Component {
    var velocity: SIMD3<Float>
    var radius: Float
    var type: BodyType
}
