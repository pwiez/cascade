import SwiftUI
import RealityKit

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
        arView.renderOptions = [.disableMotionBlur, .disableDepthOfField]
        simulation.engine.attach(to: arView)
        wrapper.arView = arView
        wrapper.addSubview(arView)
        return wrapper
    }
    
    func updateUIView(_ uiView: ARViewContainer, context: Context) { }
}

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    
    @State private var showRespawnAlert = false
    
    let respawnTip = RespawnTip()
    let detonateTip = DetonateTip()
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            ZStack {
                SimulationContainer(simulation: simulation)
                
                VStack {
                    HStack(alignment: .top) {
                        SimMetrics(sim: simulation)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Simulation Status")
                            .accessibilityValue("\(simulation.debrisCount) debris pieces, \(simulation.activeSatellites) satellites active.")
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            
                            Button(action: {
                                showRespawnAlert = true
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.red.opacity(0.8))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                            }
                            .accessibilityLabel("Respawn Simulation")
                            .popoverTip(respawnTip, arrowEdge: .top)
                            .confirmationDialog(
                                "Restart Simulation?",
                                isPresented: $showRespawnAlert,
                                titleVisibility: .visible
                            ) {
                                Button("Respawn", role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                    simulation.resetSimulation()
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("This will delete all current debris and reset the simulation.")
                            }
                            
                            Button(action: {
                                simulation.isPaused.toggle()
                                hapticFeedback.impactOccurred()
                            }) {
                                Image(systemName: simulation.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.orange.opacity(0.9))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                    
                            }
                            .accessibilityLabel(simulation.isPaused ? "Resume Simulation" : "Pause Simulation")
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    simulation.resetCamera()
                                }
                                UIAccessibility.post(notification: .announcement, argument: "Camera reset to default orbit")
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                    Text("Reset View")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(.cyan)
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                            }
                            .accessibilityLabel("Reset Camera")
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        simulation.triggerDetonation()
                        hapticFeedback.impactOccurred()
                        UIAccessibility.post(notification: .announcement, argument: "Detonation triggered")
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("DETONATE A SATELLITE")
                                .fontWeight(.heavy)
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: 300)
                        .foregroundStyle(.white)
                        .background(Color.red.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                    }
                    .popoverTip(detonateTip, arrowEdge: .bottom)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Trigger Detonation")
                }
            }
            .tabItem {
                Label("Simulation", systemImage: "play.circle.fill")
            }
            .tag(0)
            
            SettingsView(simulation: simulation)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
                .tag(1)
            
            KnowledgeView()
                .tabItem {
                    Label("Learn More", systemImage: "book.fill")
                }
                .tag(2)
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 {
                simulation.resumeSimulation()
            } else {
                simulation.pauseSimulation()
            }
        }
    }
}

struct SimulationContainer: View {
    @ObservedObject var simulation: Simulation
    
    @State private var previousDrag: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        SimulationView(simulation: simulation)
            .ignoresSafeArea()
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            let sensitivity: Float = 0.005
                            let deltaY = Float(value.translation.width - previousDrag.width) * -sensitivity
                            let deltaX = Float(value.translation.height - previousDrag.height) * -sensitivity
                            
                            previousDrag = value.translation
                            simulation.rotateCamera(deltaX: deltaX, deltaY: deltaY)
                        }
                        .onEnded { _ in previousDrag = .zero },
                    
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = Float(value / lastScale)
                            lastScale = value
                            simulation.zoomCamera(scaleFactor: delta)
                        }
                        .onEnded { _ in lastScale = 1.0 }
                )
            )
            .accessibilityLabel("3D Simulation View")
            .accessibilityHint("Drag with one finger to rotate. Pinch with two fingers to zoom.")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}
