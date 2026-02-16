import SwiftUI
import RealityKit
import TipKit

struct SimulationControls: View {
    @Binding var isPaused: Bool
    @Binding var showSettings: Bool
    let onResetCamera: () -> Void
    let onDetonate: () -> Void
    
    var body: some View {
        GlassEffectContainer(spacing: 24) {
            VStack(spacing: 24) {
                
                Button(action: onDetonate) {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)
                
                
                CircleButton(
                    icon: "camera.viewfinder",
                    color: .blue,
                    isActive: false,
                    action: onResetCamera
                )

                CircleButton(
                    icon: isPaused ? "play.fill" : "pause.fill",
                    color: .green,
                    isActive: isPaused
                ) {
                    isPaused.toggle()
                }
                
                CircleButton(
                    icon: "gear",
                    color: .blue,
                    isActive: showSettings
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSettings.toggle()
                    }
                }
            }
        }
        .padding(16)
    }
}

struct CircleButton: View {
    let icon: String
    let color: Color
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isActive ? .black : color)
                .frame(width: 48, height: 48)
        }
        .tint(isActive ? color : nil)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(icon.replacingOccurrences(of: ".fill", with: ""))
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
