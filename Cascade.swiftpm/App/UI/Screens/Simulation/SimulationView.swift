//
//  SimulationView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 11/02/26.
//

import CascadeEngine
import RealityKit
import SwiftUI

struct SimulationView: UIViewRepresentable {
    let simulation: Simulation

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)

        arView.renderOptions = [
            .disableMotionBlur, .disableCameraGrain, .disableFaceMesh, .disableGroundingShadows
        ]
        arView.environment.lighting.intensityExponent = -1.0

        simulation.attachToView(arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
