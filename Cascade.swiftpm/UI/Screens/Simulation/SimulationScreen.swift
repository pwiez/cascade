//
//  SimulationScreen.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

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
                
                
                if simulation.showStats {
                    VStack {
                        Spacer()
                        HStack {
                            SimulationMetrics(
                                telemetry: simulation.telemetry,
                                initialSatellites: simulation.initialSatelliteCount,
                                satelliteColor: simulation.satelliteColor,
                                debrisColor: simulation.debrisColor
                            )
                            Spacer()
                        }
                        .padding(.leading)
                        .padding(.bottom)
                    }
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
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                }
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
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
                        .padding(.vertical)
                        .padding(.trailing)
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
