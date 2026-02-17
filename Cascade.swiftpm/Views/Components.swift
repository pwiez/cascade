import SwiftUI
import RealityKit
import TipKit

struct SimulationControls: View {
    @Binding var isPaused: Bool
    @Binding var showSettings: Bool
    let onResetCamera: () -> Void
    let onDetonate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            
            SimulationButton(
                icon: "burst.fill",
                action: onDetonate,
                isProminent: true,
                tint: .red
            )
            .accessibilityLabel("Detonate Satellite")
            
            SimulationButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                action: { isPaused.toggle() },
                isProminent: false,
                tint: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
            .accessibilityLabel(isPaused ? "Resume Simulation" : "Pause Simulation")
            
            SimulationButton(
                icon: "camera.metering.center.weighted",
                action: onResetCamera,
                isProminent: false,
                tint: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
            .accessibilityLabel("Reset Camera")
            
            SimulationButton(
                icon: "gearshape.fill",
                action: { showSettings.toggle() },
                isProminent: false,
                tint: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
            .accessibilityLabel("Open Settings")
        }
    }
}

struct SimulationButton: View {
    let icon: String
    let action: () -> Void
    let isProminent: Bool
    var tint: Color?
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
        .modifier(GlassStyleModifier(isProminent: isProminent, tint: tint))
    }
}

struct GlassStyleModifier: ViewModifier {
    var isProminent: Bool
    var tint: Color?

    func body(content: Content) -> some View {
        if isProminent {
            content.buttonStyle(.glassProminent)
                .tint(tint)
        } else {
            content.buttonStyle(.glass)
        }
    }
}

class ARViewContainer: UIView {
    var arView: ARView?
    override func layoutSubviews() {
        super.layoutSubviews()
        arView?.frame = self.bounds
    }
}

struct SimulationView: UIViewRepresentable {
    @ObservedObject var simulation: Simulation
    
    func makeUIView(context: Context) -> ARViewContainer {
        let wrapper = ARViewContainer()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        
        let spaceColor = UIColor(red: 0.05, green: 0.05, blue: 0.09, alpha: 1.0)
        arView.environment.background = .color(spaceColor)
        
        arView.renderOptions = [
            .disableMotionBlur,
            .disableDepthOfField,
            .disableFaceMesh,
            .disableHDR,
            .disableGroundingShadows
        ]
        
        simulation.attachToView(arView)
        
        wrapper.arView = arView
        wrapper.addSubview(arView)
        return wrapper
    }
    
    func updateUIView(_ uiView: ARViewContainer, context: Context) { }
}

#Preview("Command Strip") {
    @Previewable @State var isPaused = false
    @Previewable @State var showSettings = false
    
    SimulationControls(
        isPaused: $isPaused,
        showSettings: $showSettings,
        onResetCamera: { print("Camera Reset") },
        onDetonate: { print("Boom") }
    )
    .padding()
    .background(Color(red: 0.07, green: 0.07, blue: 0.12))
}

