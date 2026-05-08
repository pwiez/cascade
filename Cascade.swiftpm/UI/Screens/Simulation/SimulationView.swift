import SwiftUI
import RealityKit

struct SimulationView: UIViewRepresentable {
    let simulation: Simulation

    func makeUIView(context: Context) -> ARViewContainer {
        let wrapper = ARViewContainer()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)

        let spaceColor = UIColor(red: 0.05, green: 0.05, blue: 0.09, alpha: 1.0)
        arView.environment.background = .color(spaceColor)
        arView.environment.lighting.intensityExponent = -1.0

        arView.renderOptions = [
            .disableMotionBlur, .disableCameraGrain, .disableFaceMesh, .disableGroundingShadows
        ]

        simulation.attachToView(arView)

        wrapper.arView = arView
        wrapper.addSubview(arView)
        return wrapper
    }

    func updateUIView(_ uiView: ARViewContainer, context: Context) { }
}
