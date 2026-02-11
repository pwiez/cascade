import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            ZStack {
                SimulationContainer(simulation: simulation)
                
                VStack {
                    HStack(alignment: .top) {
                        SimMetrics(sim: simulation)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Simulation Status")
                            .accessibilityValue("\(simulation.debrisCount) debris pieces, \(simulation.leoRemaining) satellites remaining.")
                        
                        Spacer()
                        
                        Button(action: {
                            simulation.resetCamera()
                            UIAccessibility.post(notification: .announcement, argument: "Camera reset to default view")
                        }) {
                            Label("Reset View", systemImage: "camera.viewfinder")
                                .font(.caption.bold())
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                        }
                        .accessibilityLabel("Reset Camera")
                        .accessibilityHint("Returns the camera to the starting position.")
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        simulation.requestDetonation()
                        impactFeedback.impactOccurred()
                        UIAccessibility.post(notification: .announcement, argument: "Detonation triggered")
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("TRIGGER DETONATION")
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
                    .padding(.bottom, 20)
                    .accessibilityLabel("Trigger Detonation")
                    .accessibilityHint("Explodes a random satellite to start the chain reaction.")
                }
                
                if let fact = simulation.currentFact {
                    FactOverlay(fact: fact) {
                        simulation.resumeSimulation()
                    }
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
                    Label("Encyclopedia", systemImage: "book.fill")
                }
                .tag(2)
        }
        .preferredColorScheme(.dark)
    }
}

struct SimulationContainer: View {
    @ObservedObject var simulation: Simulation
    @State private var previousDrag: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        SceneView(
            scene: simulation.scene,
            pointOfView: simulation.cameraNode,
            options: [.autoenablesDefaultLighting, .rendersContinuously],
            delegate: simulation
        )
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
        .accessibilityHint("Use one finger to rotate, two fingers to zoom.")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

struct FactOverlay: View {
    let fact: SpaceFact
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityLabel("Dismiss Popup")
            
            VStack(spacing: 20) {
                Image(systemName: fact.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                
                Text(fact.title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(fact.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button("Resume Simulation", action: onDismiss)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .accessibilityHint("Closes this fact card.")
            }
            .padding(30)
            .background(.thickMaterial)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}
