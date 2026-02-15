import SwiftUI
import RealityKit
import TipKit

struct ControlOverlay: View {
    @Binding var showSettings: Bool
    @Binding var isPaused: Bool
    let onResetCamera: () -> Void
    
    let settingsTip = SettingsTip()
    
    var body: some View {
        HStack(spacing: 12) {
            CircleButton(
                icon: showSettings ? "xmark" : "gear",
                color: showSettings ? .gray : .blue,
                isActive: showSettings
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showSettings.toggle()
                }
            }
            
            CircleButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                color: isPaused ? .green : .orange,
                isActive: isPaused
            ) {
                isPaused.toggle()
            }
            
            CircleButton(
                icon: "camera.viewfinder",
                color: .cyan,
                isActive: false
            ) {
                onResetCamera()
            }
        }
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
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .glassEffect()
        }
    }
}

struct DetonateButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                Text("DETONATE")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.heavy)
                    .tracking(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.red)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
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
