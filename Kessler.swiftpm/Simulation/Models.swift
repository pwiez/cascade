import Foundation
import SceneKit

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
    var node: SCNNode
    
    var isDebris: Bool { return type == .debris }
    
    init(node: SCNNode, pos: SIMD3<Float>, vel: SIMD3<Float>, radius: Float, type: BodyType) {
        self.node = node
        self.position = pos
        self.velocity = vel
        self.radius = radius
        self.type = type
        self.node.position = SCNVector3(pos.x, pos.y, pos.z)
    }
}

enum MenuSelection: String, CaseIterable, Identifiable {
    case simulation = "Simulation"
    case settings = "Parameters"
    case encyclopedia = "Encyclopedia"
    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .simulation: return "play.circle.fill"
        case .settings: return "slider.horizontal.3"
        case .encyclopedia: return "book.fill"
        }
    }
}
