import Foundation
import RealityKit
import simd

enum BodyType { case leo, meo, geo, debris }

struct OrbitalData: Component {
    var velocity: SIMD3<Float>
    var radius: Float
    var type: BodyType
}

struct CollisionEvent: Sendable {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
}

struct SimulationFrame: Sendable {
    let count: Int

    let posX: [Float]
    let posY: [Float]
    let posZ: [Float]

    let rotAngle: [Float]
    let rotAxisX: [Float]
    let rotAxisY: [Float]
    let rotAxisZ: [Float]

    let killedSatelliteIndices: [Int]
    let explosions: [CollisionEvent]

    static let empty = SimulationFrame(
        count: 0,
        posX: [], posY: [], posZ: [],
        rotAngle: [], rotAxisX: [], rotAxisY: [], rotAxisZ: [],
        killedSatelliteIndices: [],
        explosions: []
    )
}

struct SpaceFact: Identifiable, Equatable {
    let id = UUID()
    let title, description, icon: String
}
