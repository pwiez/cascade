import SwiftUI
import TipKit

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    @State private var showIntro: Bool = true
    
    @State private var wasPlayingBeforeRotation: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            
            ZStack {
                
                TabView(selection: $selectedTab) {
                    SimulationScreen(simulation: simulation)
                        .tabItem { Label("Simulation", systemImage: "cube.transparent") }
                        .tag(0)
                    
                    LearnMoreView()
                        .tabItem { Label("Learn More", systemImage: "book.closed.fill") }
                        .tag(1)
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == 1 { simulation.pauseSimulation() }
                    else if newTab == 0 && !showIntro { simulation.resumeSimulation() }
                }
                .disabled(isPortrait || showIntro)
                .blur(radius: showIntro ? 16 : 0)
                .animation(.easeInOut(duration: 0.4), value: showIntro)
                
                
                if showIntro && !isPortrait {
                    OnboardingOverlay {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            showIntro = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            simulation.startSimulation()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(2000)
                }
                
                
                if isPortrait {
                    PortraitWarningView()
                        .zIndex(3000)
                        .transition(.opacity.animation(.easeInOut))
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                let currentPortrait = newSize.height > newSize.width
                let wasPortrait = oldSize.height > oldSize.width
                
                if currentPortrait && !wasPortrait {
                    wasPlayingBeforeRotation = !simulation.isPaused
                    simulation.pauseSimulation()
                }
                else if !currentPortrait && wasPortrait {
                    
                    if wasPlayingBeforeRotation && !showIntro {
                        simulation.resumeSimulation()
                    }
                }
            }
        }
    }
}
