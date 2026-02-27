import SwiftUI

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    @State private var showIntro: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            
            ZStack {
                ZStack {
                    TabView(selection: $selectedTab) {
                        SimulationScreen(simulation: simulation)
                            .tabItem { Label("Simulation", systemImage: "cube.transparent") }
                            .tag(0)
                        
                        LearnMoreView()
                            .tabItem { Label("Learn More", systemImage: "book.closed.fill") }
                            .tag(1)
                    }
                    .blur(radius: showIntro ? 16 : 0)
                    .animation(.easeInOut(duration: 0.4), value: showIntro)
                    
                    if showIntro {
                        OnboardingOverlay {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                showIntro = false
                            } completion: {
                                simulation.startSimulation()
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .zIndex(1)
                    }
                }
                .blur(radius: isPortrait ? 20 : 0)
                .disabled(isPortrait)
                
                if isPortrait {
                    PortraitWarningView()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .animation(.default, value: isPortrait)
            .onChange(of: geometry.size) { oldSize, newSize in
                let currentPortrait = newSize.height > newSize.width
                let wasPortrait = oldSize.height > oldSize.width
                
                if currentPortrait && !wasPortrait {
                    simulation.pauseSimulation()
                }
            }
        }
    }
}
