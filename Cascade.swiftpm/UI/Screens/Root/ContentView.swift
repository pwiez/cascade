//
//  ContentView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 09/02/26.
//

import SwiftUI

struct ContentView: View {
    @State private var simulation = Simulation()
    @State private var selectedTab: AppTab = .simulation
    @State private var showIntro: Bool = true
    @State private var wasPlayingBeforeRotation: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width

            ZStack {
                ZStack {
                    TabView(selection: $selectedTab) {
                        Tab("Simulation", systemImage: "cube.transparent", value: AppTab.simulation) {
                            SimulationScreen(simulation: simulation)
                        }
                        Tab("Learn More", systemImage: "book.closed.fill", value: AppTab.learnMore) {
                            LearnMoreView()
                        }
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
