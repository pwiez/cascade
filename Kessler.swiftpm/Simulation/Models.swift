import Foundation
import RealityKit

enum BodyType { case leo, meo, geo, debris }

struct SpaceFact: Identifiable, Equatable {
    let id = UUID()
    let title, description, icon: String
}

class PhysicsBody: Identifiable {
    let id = UUID()
    
    var position: SIMD3<Float>
    var velocity: SIMD3<Float>
    var radius: Float
    var type: BodyType
    
    var entity: ModelEntity
    
    var isDebris: Bool { return type == .debris }
    
    init(entity: ModelEntity, pos: SIMD3<Float>, vel: SIMD3<Float>, radius: Float, type: BodyType) {
        self.entity = entity
        self.position = pos
        self.velocity = vel
        self.radius = radius
        self.type = type
        
        self.entity.position = pos
    }
}
