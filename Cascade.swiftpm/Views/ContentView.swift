import SwiftUI
import TipKit

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    @State private var showIntro: Bool = true
    
    @State private var wasPlayingBeforeRotation: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !showIntro {
                    Group {
                        TabView(selection: $selectedTab) {
                            SimulationScreen(simulation: simulation)
                                .tabItem { Label("Simulation", systemImage: "cube.transparent") }
                                .tag(0)
                            
                            KesslerDeepDiveView()
                                .tabItem { Label("Learn More", systemImage: "book.closed.fill") }
                                .tag(1)
                        }
                        .onChange(of: selectedTab) { _, newTab in
                            if newTab == 1 { simulation.pauseSimulation() }
                            else if newTab == 0 { simulation.resumeSimulation() }
                        }
                    }
                    .disabled(geometry.size.height > geometry.size.width)
                    .blur(radius: geometry.size.height > geometry.size.width ? 10 : 0)
                    .transition(.opacity)
                }
                
                if showIntro {
                    IntroScreen {
                        withAnimation(.easeOut(duration: 0.6)) {
                            showIntro = false
                        }
                        simulation.startSimulation()
                    }
                    .zIndex(200)
                    .transition(.opacity)
                }
                
                if geometry.size.height > geometry.size.width {
                    PortraitWarningView()
                        .zIndex(1000)
                        .transition(.opacity.animation(.easeInOut))
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                let isPortrait = newSize.height > newSize.width
                let wasPortrait = oldSize.height > oldSize.width
                
                if isPortrait && !wasPortrait {
                    wasPlayingBeforeRotation = !simulation.isPaused
                    simulation.pauseSimulation()
                }
                else if !isPortrait && wasPortrait {
                    if wasPlayingBeforeRotation {
                        simulation.resumeSimulation()
                    }
                }
            }
        }
    }
}

struct IntroScreen: View {
    var onEnter: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea()
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe.americas.fill")
                                .foregroundStyle(.blue)
                            Text("INTRODUCTION")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.blue)
                                .tracking(1.2)
                        }
                        
                        Text("Cascade")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("A Kessler Syndrome Simulator")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    
                    Spacer().frame(height: 44)
                    
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Low Earth Orbit is getting crowded. Thousands of satellites share space with millions of debris fragments — and at orbital speeds, even a fleck of paint hits like a bullet.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(6)
                        
                        Text("Cascade lets you explore what happens when collisions start a chain reaction. Trigger a detonation, watch debris spread, and see how one event can spiral out of control.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: 500)
                    
                    Spacer()
                    
                    Button(action: onEnter) {
                        Text("Enter Simulation")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 54)
                            .background(.blue)
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.4), radius: 10, y: 4)
                    }
                    .accessibilityHint("Starts the orbital debris simulation")
                    .padding(.bottom, 60)
                }
                .padding(.leading, 64)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    IntroFeatureCard(
                        icon: "cube.transparent",
                        title: "Simulate",
                        description: "Watch satellites orbit Earth in real time. Trigger collisions and observe how debris cascades through orbital shells."
                    )
                    
                    IntroFeatureCard(
                        icon: "book.closed.fill",
                        title: "Learn More",
                        description: "Read about the science behind orbital debris — from collision mechanics to the strategies engineers are developing to clean up orbit."
                    )
                    
                    IntroFeatureCard(
                        icon: "gearshape.fill",
                        title: "Configure",
                        description: "Adjust satellite count, debris physics, explosion force, and time scale to explore different scenarios."
                    )
                    
                    Spacer()
                }
                .frame(maxWidth: 380)
                .padding(.trailing, 64)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct IntroFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct SimulationScreen: View {
    @ObservedObject var simulation: Simulation
    @State private var showSettings = false
    
    private let panelWidthRatio = 0.30
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                SimulationContainer(simulation: simulation)
                    .ignoresSafeArea()
                    .zIndex(0)
                    .accessibilityLabel("Orbital debris simulation")
                    .accessibilityHint("Drag to rotate the camera. Pinch to zoom in or out.")
                
                
                if simulation.showStats {
                    SimMetrics(telemetry: simulation.telemetry, initialSatellites: simulation.initialSatelliteCount)
                        .padding(.top, 24)
                        .padding(.leading, 80)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                }
                
                HStack {
                    SimulationControls(
                        isPaused: $simulation.isPaused,
                        showSettings: $showSettings,
                        onResetCamera: { simulation.resetCamera() },
                        onDetonate: { simulation.triggerDetonation() }
                    )
                    Spacer()
                }
                .padding(.leading, 24)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
                .zIndex(2)
                
                VStack {
                    Spacer()
                    Text("This simulation is not-to-scale.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 12)
                }
                .allowsHitTesting(false)
                .zIndex(1)
                
                if showSettings {
                    HStack {
                        Spacer()
                        SettingsView(
                            simulation: simulation,
                            onClose: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showSettings = false
                                }
                            }
                        )
                        .frame(width: geometry.size.width * panelWidthRatio)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.vertical, 24)
                        .padding(.trailing, 24)
                        .transition(.move(edge: .trailing))
                    }
                    .zIndex(3)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSettings)
            .onChange(of: showSettings) { _, isOpen in
                updateCameraOffset(isOpen: isOpen, geometry: geometry)
            }
            .onChange(of: geometry.size) { _, newSize in
                if showSettings {
                    updateCameraOffset(isOpen: true, geometry: geometry)
                }
            }
        }
    }
    
    @MainActor
    private func updateCameraOffset(isOpen: Bool, geometry: GeometryProxy) {
        if isOpen {
            let aspect = geometry.size.width / geometry.size.height
            let shiftRatio = (panelWidthRatio / 2.0) * 0.6875
            simulation.setSettingsPanel(isOpen: true, ratio: shiftRatio, aspectRatio: Double(aspect))
        } else {
            let aspect = geometry.size.width / geometry.size.height
            simulation.setSettingsPanel(isOpen: false, ratio: 0, aspectRatio: Double(aspect))
        }
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

struct PortraitWarningView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "ipad.landscape")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(spacing: 12) {
                    Text("Rotate your iPad")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                    
                    Text("Cascade works best in landscape mode.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Please rotate your iPad to landscape orientation. Cascade works best in landscape mode.")
        }
    }
}
