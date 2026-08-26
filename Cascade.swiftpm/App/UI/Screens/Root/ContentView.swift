//
//  ContentView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 09/02/26.
//

import CascadeEngine
import SwiftUI

/// The app's root: two tabs, an onboarding overlay on first launch, and a
/// portrait guard.
struct ContentView: View {
    @State private var simulation = Simulation()
    @State private var selectedTab: AppTab = .simulation
    @State private var showIntro = true
    @State private var isPortrait = false

    /// Whether the simulation was running before the device rotated, so it can be
    /// put back the way the user left it.
    @State private var wasPlayingBeforeRotation = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Simulation", systemImage: "cube.transparent", value: AppTab.simulation) {
                    SimulationScreen(simulation: simulation)
                }
                Tab("Learn More", systemImage: "book.closed.fill", value: AppTab.learnMore) {
                    LearnMoreView()
                }
            }
            .blur(radius: backgroundBlur)
            .animation(.easeInOut(duration: 0.4), value: showIntro)
            .disabled(isPortrait)
            .onAppear(perform: simulation.startSimulation)

            if showIntro {
                OnboardingOverlay(onDismiss: dismissIntro)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(1)
            }

            if isPortrait {
                PortraitWarningView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.default, value: isPortrait)
        .onGeometryChange(for: Bool.self) { $0.size.height > $0.size.width } action: { nowPortrait in
            handleOrientationChange(isNowPortrait: nowPortrait)
        }
    }

    /// The intro and the portrait warning both dim what's behind them; blurring
    /// twice would only cost another pass.
    private var backgroundBlur: CGFloat {
        if isPortrait { 20 } else if showIntro { 16 } else { 0 }
    }

    private func dismissIntro() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25)
                                   : .spring(response: 0.45, dampingFraction: 0.85)) {
            showIntro = false
        }
    }

    /// Pauses on rotation into portrait, and resumes only if it was running when
    /// the rotation started.
    private func handleOrientationChange(isNowPortrait: Bool) {
        guard isNowPortrait != isPortrait else { return }
        isPortrait = isNowPortrait

        if isNowPortrait {
            wasPlayingBeforeRotation = !simulation.isPaused
            simulation.pauseSimulation()
        } else if wasPlayingBeforeRotation {
            simulation.resumeSimulation()
        }
    }
}
