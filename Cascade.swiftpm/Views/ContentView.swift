import SwiftUI
import TipKit

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    let learnMoreTip = LearnMoreTip()
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    
                    SimulationScreen(simulation: simulation)
                        .tabItem {
                            Label("Simulation", systemImage: "cube.transparent")
                        }
                        .tag(0)
                    
                    KnowledgeView()
                        .tabItem {
                            Label("Learn More", systemImage: "book.closed.fill")
                        }
                        .tag(1)
                        .badge(learnMoreTip.shouldDisplay ? "!" : nil)
                }
                .preferredColorScheme(.dark)
                .transition(.opacity)
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == 1 {
                        simulation.pauseSimulation()
                        learnMoreTip.invalidate(reason: .actionPerformed)
                    } else if newTab == 0 {
                        simulation.resumeSimulation()
                    }
                }
            }
            
            if simulation.showCollisionAlert {
                CinematicOverlay(simulation: simulation)
                    .zIndex(100)
                    .transition(.opacity)
            }
            
            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.easeIn(duration: 1.0)) {
                        hasCompletedOnboarding = true
                    }
                }
                .zIndex(200)
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct CinematicOverlay: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse)
                
                Text("COLLISION DETECTED")
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("A collision has generated debris fragments.\nEach fragment is a projectile moving at 17,500 mph.\nIf they hit other satellites, a chain reaction will begin.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal)
                
                Button {
                    simulation.dismissCollisionAlert()
                } label: {
                    Text("RESUME SIMULATION")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .padding(40)
            .frame(maxWidth: 600)
            .padding(.trailing, 700)
        }
    }
}

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var step = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { proxy in
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 4, height: 4)
                        .position(
                            x: CGFloat.random(in: 0...proxy.size.width),
                            y: CGFloat.random(in: 0...proxy.size.height)
                        )
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                TabView(selection: $step) {
                    onboardingPage(
                        title: "The Kessler Syndrome",
                        desc: "Low Earth Orbit is becoming crowded. Thousands of satellites circle our planet right now.",
                        icon: "globe.europe.africa.fill",
                        color: .blue
                    ).tag(0)
                    
                    onboardingPage(
                        title: "The Danger",
                        desc: "At orbital speeds, a screw hits with the force of a grenade. One crash can create thousands of bullets.",
                        icon: "burst.fill",
                        color: .red
                    ).tag(1)
                    
                    onboardingPage(
                        title: "Your Goal",
                        desc: "Explore the physics. Trigger a detonation. Watch the cascade effect unfold.",
                        icon: "eye.fill",
                        color: .green
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
                
                Button {
                    if step < 2 {
                        withAnimation { step += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(step == 2 ? "ENTER SIMULATION" : "NEXT")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .frame(width: 200, height: 50)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    func onboardingPage(title: String, desc: String, icon: String, color: Color) -> some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
            
            Text(desc)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .padding(.horizontal, 40)
        }
    }
}

struct SimulationScreen: View {
    @ObservedObject var simulation: Simulation
    @State private var showSettings = false
    
    var body: some View {
        GeometryReader { geometry in
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
                        .frame(width: geometry.size.width * 0.33)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 75)
                        .padding(.bottom, 16)
                        .padding(.trailing, 16)
                        .transition(.move(edge: .trailing))
                        .zIndex(2)
                }
                
                ControlOverlay(
                    showSettings: $showSettings,
                    isPaused: $simulation.isPaused,
                    onResetCamera: { simulation.resetCamera() }
                )
                .padding(.trailing)
                .padding(.top)
                .zIndex(3)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSettings)
            .onChange(of: showSettings) { simulation.setSettingsOpen(showSettings) }
            .task {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
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
