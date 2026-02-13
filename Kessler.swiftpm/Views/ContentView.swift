import SwiftUI

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            SimulationScreen(simulation: simulation)
                .tabItem {
                    Label("Simulation", systemImage: "cube.transparent")
                }
                .tag(0)
            
            KnowledgeView()
                .tabItem {
                    Label("Encyclopedia", systemImage: "book.closed.fill")
                }
                .tag(1)
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { newTab in
            if newTab == 1 {
                simulation.pauseSimulation()
            } else if newTab == 0 {
                simulation.resumeSimulation()
            }
        }
    }
}

struct SimulationScreen: View {
    @ObservedObject var simulation: Simulation
    @State private var showSettings = false
    
    #if os(iOS)
    private let settingsWidth: CGFloat = 360
    #else
    private let settingsWidth: CGFloat = 400
    #endif
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            SimulationContainer(simulation: simulation)
                .ignoresSafeArea()
                .zIndex(0)
            
            ZStack(alignment: .bottom) {
                if simulation.showStats {
                    VStack {
                        HStack {
                            SimMetrics(sim: simulation)
                                .padding(.leading, 20)
                                .padding(.top, 20)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                DetonateButton {
                    simulation.triggerDetonation()
                }
                .padding(.bottom, 30)
            }
            .zIndex(1)
            
            if showSettings {
                SettingsView(simulation: simulation)
                    .frame(width: settingsWidth)
                    .background(Color(uiColor: .systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 20)
                    .padding(.top, 70)
                    .padding(.bottom, 20)
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
            }
            
            ControlOverlay(
                showSettings: $showSettings,
                isPaused: $simulation.isPaused,
                onResetCamera: { simulation.resetCamera() }
            )
            .padding(.trailing, 16)
            .padding(.top, 16)
            .zIndex(3)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSettings)
        .onChange(of: showSettings) { simulation.setSettingsOpen(showSettings) }
    }
}

struct SimulationContainer: View {
    @ObservedObject var simulation: Simulation
    
    @State private var previousDrag: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        SimulationView(simulation: simulation)
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            guard !simulation.isCameraLocked else { return }
                            
                            let sensitivity: Float = 0.005
                            let deltaY = Float(value.translation.width - previousDrag.width) * -sensitivity
                            let deltaX = Float(value.translation.height - previousDrag.height) * -sensitivity
                            
                            previousDrag = value.translation
                            simulation.rotateCamera(deltaX: deltaX, deltaY: deltaY)
                        }
                        .onEnded { _ in previousDrag = .zero },
                    
                    MagnificationGesture()
                        .onChanged { value in
                            guard !simulation.isCameraLocked else { return }
                            
                            let delta = Float(value / lastScale)
                            lastScale = value
                            simulation.zoomCamera(scaleFactor: delta)
                        }
                        .onEnded { _ in lastScale = 1.0 }
                )
            )
    }
}
