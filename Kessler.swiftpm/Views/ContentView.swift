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
    @State private var showSettings = false
    
    let respawnTip = RespawnTip()
    let detonateTip = DetonateTip()
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                
                HStack(spacing: 0) {
                    
                    ZStack {
                        SimulationContainer(simulation: simulation)
                            .ignoresSafeArea()
                        
                        VStack {
                            HStack(alignment: .top) {
                                SimMetrics(sim: simulation)
                                Spacer()
                            }
                            .padding()
                            .padding(.top, 20)
                            
                            Spacer()
                            
                            Button(action: {
                                simulation.triggerDetonation()
                                hapticFeedback.impactOccurred()
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("DETONATE")
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
                            .padding(.bottom, 30)
                        }
                    }
                    .frame(width: showSettings ? geo.size.width * 0.65 : geo.size.width)
                    .clipped()
                    
                    if showSettings {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: 100)
                            
                            UnifiedSettingsView(simulation: simulation, isPresented: $showSettings)
                                .padding(.bottom, 20)
                                .padding(.trailing, 16)
                                .padding(.leading, 8)
                        }
                        .frame(width: geo.size.width * 0.35)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .zIndex(1)
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSettings)
                
                HStack(spacing: 12) {
                    
                    Button(action: {
                        withAnimation { showSettings.toggle() }
                        hapticFeedback.impactOccurred()
                    }) {
                        Image(systemName: showSettings ? "chevron.right" : "slider.horizontal.3")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
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
                    
                    Button(action: {
                        simulation.resetCamera()
                    }) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.blue.opacity(0.9))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding()
                .padding(.top, 10)
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
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
