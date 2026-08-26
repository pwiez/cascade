import CascadeEngine
import RealityKit
import SwiftUI

/// Hosts the RealityKit view that renders the simulation.
///
/// Still `UIViewRepresentable` rather than `RealityView`: the app needs
/// `ARView.renderOptions` to switch off effects it never uses, and its own
/// clamped orbit camera, neither of which `RealityView` exposes on iOS 18.
/// `ARView` is not deprecated, so this stays the right tool.
struct SimulationView: UIViewRepresentable {
    let simulation: Simulation

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)

        // Nothing in an orbital scene benefits from these, and each one costs a
        // pass over the frame.
        arView.renderOptions = [
            .disableMotionBlur, .disableCameraGrain, .disableFaceMesh, .disableGroundingShadows
        ]
        arView.environment.lighting.intensityExponent = -1.0

        simulation.attachToView(arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
