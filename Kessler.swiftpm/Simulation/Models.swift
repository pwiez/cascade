import Foundation
import RealityKit

enum BodyType { case leo, meo, geo, debris }

struct SpaceFact: Identifiable, Equatable {
    let id = UUID()
    let title, description, icon: String
}

struct OrbitalData: Component {
    var velocity: SIMD3<Float>
    var radius: Float
    var type: BodyType
}
