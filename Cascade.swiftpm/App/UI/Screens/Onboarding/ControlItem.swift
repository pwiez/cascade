//
//  ControlItem.swift
//  Cascade
//
//  Created by Pedro Wiezel on 27/05/26.
//

import SwiftUI

struct ControlItem: Identifiable {
    let id: String
    let icon: String
    let tint: Color
    let name: String
    let detail: String

    init(icon: String, tint: Color, name: String, detail: String) {
        self.id = name
        self.icon = icon
        self.tint = tint
        self.name = name
        self.detail = detail
    }
}

extension ControlItem {
    static let simulationControls: [ControlItem] = [
        .init(icon: "burst.fill", tint: .red,
              name: "Detonate", detail: "Explode a random satellite"),
        .init(icon: "arrow.triangle.2.circlepath", tint: .orange,
              name: "Restart", detail: "Reset the simulation"),
        .init(icon: "play.fill", tint: .green,
              name: "Play / Pause", detail: "Start or pause time"),
        .init(icon: "camera.metering.center.weighted", tint: .primary,
              name: "Reset Camera", detail: "Recenter the view"),
        .init(icon: "gearshape.fill", tint: .primary,
              name: "Settings", detail: "Visuals and parameters")
    ]

    static let cameraControls: [ControlItem] = [
        .init(icon: "hand.draw.fill", tint: .primary,
              name: "Drag", detail: "Orbit the camera around Earth"),
        .init(icon: "hand.pinch.fill", tint: .primary,
              name: "Pinch", detail: "Zoom in and out")
    ]
}
