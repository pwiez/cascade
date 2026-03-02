//
//  ContentView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 09/02/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedTab: Int = 0
    @State private var showIntro: Bool = true
    
    @State private var wasPlayingBeforeRotation: Bool = false
    
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
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .zIndex(1)
                    }
                }
                .onAppear {
                    simulation.startSimulation()
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
                    wasPlayingBeforeRotation = !simulation.isPaused
                    simulation.pauseSimulation()
                } else if !currentPortrait && wasPortrait {
                    if wasPlayingBeforeRotation {
                        simulation.resumeSimulation()
                    }
                }
            }
        }
    }
}

struct PortraitWarningView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("Please Rotate Your Device")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Cascade is designed to be experienced in landscape mode.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

