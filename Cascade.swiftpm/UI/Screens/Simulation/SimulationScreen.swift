//
//  SimulationScreen.swift
//  Cascade
//
//  Created by Pedro Wiezel on 10/02/26.
//

import SwiftUI
import RealityKit

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
                        SimulationMetrics(
                            telemetry: simulation.telemetry,
                            initialSatellites: simulation.initialSatelliteCount,
                            satelliteColor: simulation.satelliteColor,
                            debrisColor: simulation.debrisColor
                        )
                    }
                    .zIndex(1)
                }
                
                HStack {
                    SimulationControls(
                        isPaused: $simulation.isPaused,
                        showSettings: $showSettings,
                        onResetCamera: { simulation.resetCamera() },
                        onDetonate: { simulation.triggerDetonation() },
                        onRestart: { simulation.resetSimulation() }
                    )
                    Spacer()
                }
                .padding(.leading)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
                .zIndex(2)
                
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
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                    .padding(.vertical)
                    .padding(.trailing)
                    .offset(x: showSettings ? 0 : (geometry.size.width * panelWidthRatio) + 100)
                }
                .zIndex(3)
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
            let shiftRatio = (panelWidthRatio / 2.0) * 0.75
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
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard simulation.isCameraEnabled else { return }
                            
                            let sensitivity: Float = 0.005
                            let deltaY = Float(value.translation.width - previousDrag.width) * -sensitivity
                            let deltaX = Float(value.translation.height - previousDrag.height) * -sensitivity
                            
                            previousDrag = value.translation
                            simulation.rotateCamera(deltaX: deltaX, deltaY: deltaY)
                        }
                        .onEnded { _ in previousDrag = .zero },
                    
                    MagnificationGesture(minimumScaleDelta: 0)
                        .onChanged { value in
                            guard simulation.isCameraEnabled else { return }
                            
                            let delta = Float(value / lastScale)
                            lastScale = value
                            simulation.zoomCamera(scaleFactor: delta)
                        }
                        .onEnded { _ in lastScale = 1.0 }
                )
            )
    }
}

struct SimulationControls: View {
    @Binding var isPaused: Bool
    @Binding var showSettings: Bool
    let onResetCamera: () -> Void
    let onDetonate: () -> Void
    let onRestart: () -> Void
    
    @State private var showRestartConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            
            SimulationButton(
                icon: "burst.fill",
                action: onDetonate,
                isProminent: true,
                tint: .red
            )
            .accessibilityLabel("Detonate Satellite")
            .accessibilityHint("Destroys a satellite and scatters debris into orbit")
            
            SimulationButton(
                icon: "arrow.triangle.2.circlepath",
                action: { showRestartConfirmation = true },
                isProminent: false,
                tint: .clear
            )
            .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                Button("Restart", role: .destructive) {
                    onRestart()
                }
            } message: {
                Text("This will clear satellites and debris, and reset the simulation.")
            }
            .accessibilityLabel("Restart Simulation")
            .accessibilityHint("Restarts the simulation")
            
            SimulationButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                action: { isPaused.toggle() },
                isProminent: false,
                tint: .clear
            )
            .accessibilityLabel(isPaused ? "Resume Simulation" : "Pause Simulation")
            .accessibilityHint(isPaused ? "Resumes the orbital simulation" : "Pauses the orbital simulation")
            
            SimulationButton(
                icon: "camera.metering.center.weighted",
                action: onResetCamera,
                isProminent: false,
                tint: .clear
            )
            .accessibilityLabel("Reset Camera")
            .accessibilityHint("Returns the camera to its default position")
            
            SimulationButton(
                icon: "gearshape.fill",
                action: { showSettings.toggle() },
                isProminent: false,
                tint: .clear
            )
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens the simulation parameters panel")
        }
    }
}

struct SimulationButton: View {
    let icon: String
    let action: () -> Void
    let isProminent: Bool
    var tint: Color?
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
        .applyGlassStyle(isProminent: isProminent, tint: tint)
    }
}

struct SimulationMetrics: View {
    @ObservedObject var telemetry: Telemetry
    let initialSatellites: Int
    let satelliteColor: Color
    let debrisColor: Color
    
    private var stats: SimStats { telemetry.stats }
    
    var body: some View {
        HStack(spacing: 16) {
            metricItem(title: "SATELLITES", value: stats.satellites, color: satelliteColor)
            
            Divider()
                .cascadeDivider()
                .frame(height: 16)
            
            metricItem(title: "DEBRIS", value: stats.debris, color: debrisColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .glassEffect()
    }
    
    @ViewBuilder
    private func metricItem(title: String, value: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(value.formatted())
                .font(.system(.body).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
    }
}

class ARViewContainer: UIView {
    var arView: ARView?
    override func layoutSubviews() {
        super.layoutSubviews()
        arView?.frame = self.bounds
    }
}

struct SimulationView: UIViewRepresentable {
    @ObservedObject var simulation: Simulation
    
    func makeUIView(context: Context) -> ARViewContainer {
        let wrapper = ARViewContainer()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        
        let spaceColor = UIColor(red: 0.05, green: 0.05, blue: 0.09, alpha: 1.0)
        arView.environment.background = .color(spaceColor)
        arView.environment.lighting.intensityExponent = -1.0
        
        arView.renderOptions = [
            .disableMotionBlur, .disableCameraGrain, .disableFaceMesh, .disableGroundingShadows
        ]
          
        simulation.attachToView(arView)
        
        wrapper.arView = arView
        wrapper.addSubview(arView)
        return wrapper
    }
    
    func updateUIView(_ uiView: ARViewContainer, context: Context) { }
}

