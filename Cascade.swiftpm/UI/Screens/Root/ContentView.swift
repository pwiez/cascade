//
//  ContentView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

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
                            
                            LearnMoreView()
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
