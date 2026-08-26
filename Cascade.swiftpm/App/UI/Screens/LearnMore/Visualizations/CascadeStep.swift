import SwiftUI

/// One node in the self-reinforcing cascade loop.
struct CascadeStep: Identifiable {
    var id: String { title }

    let icon: String
    let color: Color
    let title: String
}

extension CascadeStep {
    static let all: [CascadeStep] = [
        .init(icon: "cube.fill", color: .green, title: "Density of objects\nin orbit increases"),
        .init(icon: "burst.fill", color: .orange, title: "A collision happens\nbetween them"),
        .init(icon: "aqi.medium", color: .red, title: "Many new objects\nare created"),
        .init(icon: "exclamationmark.triangle.fill", color: .yellow, title: "Collision risk\nincreases")
    ]
}
