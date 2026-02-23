//
//  SettingsView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    var onClose: () -> Void
    @State private var showRestartConfirmation = false
    
    var hasPendingChanges: Bool {
        simulation.draft.orbitAltitude != simulation.activeOrbitAltitude ||
        simulation.draft.orbitVariance != simulation.activeOrbitVariance ||
        simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ||
        simulation.draft.satelliteCount != simulation.activeSatelliteCount
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Camera Movement", isOn: $simulation.isCameraEnabled)
                    Toggle("Show Earth", isOn: $simulation.showEarth)
                    Toggle("Show Satellites", isOn: $simulation.showSatellites)
                    Toggle("Show Simulation Stats", isOn: $simulation.showStats)
                    Toggle("Bidirectional Light", isOn: $simulation.useOmniLight)
                    
                    DisclosureGroup("Colors & Scaling") {
                        ColorPicker("Satellite Color", selection: $simulation.satelliteColor, supportsOpacity: false)
                        ColorPicker("Debris Color", selection: $simulation.debrisColor, supportsOpacity: false)
                        ColorPicker("Universe Color", selection: $simulation.backgroundColor, supportsOpacity: false)
                        
                        NativeSliderRow(label: "Satellite Scale", value: $simulation.satelliteScale, range: 0.5...5.0, format: "%.1fx")
                        
                        if simulation.satelliteScale > (simulation.collisionRadius * 1.5) {
                            Label("Visual scale exceeds collision radius. Objects may overlap visually.", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .padding(.bottom, 4)
                        }
                        NativeSliderRow(label: "Debris Scale", value: $simulation.debrisScale, range: 0.5...5.0, format: "%.1fx")
                    }
                } header: {
                    Text("Accessibility & Visuals")
                } footer: {
                    Text("Adjust scaling to make small objects easier to see on smaller screens.")
                }
                
                Section {
                    VStack(spacing: 8) {
                        LabeledContent("Time Scale", value: String(format: "%.1fx", simulation.timeScale))
                        Slider(value: $simulation.timeScale, in: 0.1...5.0) {
                            Text("Time Scale")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise.fill")
                        } maximumValueLabel: {
                            Image(systemName: "hare.fill")
                        }
                    }
                    .padding(.vertical, 3)
                } header: {
                    Text("Simulation Speed")
                }
                
                Section {
                    NativeSliderRow(
                        label: "Initial Satellites",
                        value: $simulation.draft.satelliteCount,
                        range: 100...simulation.safeSatelliteLimit(),
                        step: 10, format: "%.0f",
                        requiresRestart: simulation.draft.satelliteCount != simulation.activeSatelliteCount
                    )
                    
                    NativeSliderRow(
                        label: "Orbit Altitude",
                        value: $simulation.draft.orbitAltitude,
                        range: 110...150,
                        step: 5,
                        format: "%.0f Units",
                        requiresRestart: simulation.draft.orbitAltitude != simulation.activeOrbitAltitude
                    )
                    
                    NativeSliderRow(
                        label: "Altitude Variance",
                        value: $simulation.draft.orbitVariance,
                        range: 0...10,
                        step: 1,
                        format: "±%.0f Units",
                        requiresRestart: simulation.draft.orbitVariance != simulation.activeOrbitVariance
                    )
                    
                    Toggle(isOn: $simulation.draft.useRandomInclination) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Randomize Orbital Planes")
                            Text(simulation.draft.useRandomInclination ? "Satellites will form a shell around Earth." : "Satellites will form a flat ring around Earth.")
                                .font(.caption)
                                .foregroundStyle(simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ? .orange : .secondary)
                        }
                    }
                    .foregroundStyle(simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ? .orange : .primary)
                    
                } header: {
                    HStack {
                        Text("Scenario Setup")
                        if hasPendingChanges {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.default)
                        }
                    }
                } footer: {
                    if hasPendingChanges {
                        Text("Applying these changes will restart the simulation.")
                            .foregroundStyle(.orange)
                    }
                }
                
                Section {
                    NativeSliderRow(label: "Earth Gravity Multiplier", value: $simulation.gravityMultiplier, range: 0.1...3.0, format: "%.1fx")
                    NativeSliderRow(label: "Debris Ejection Force", value: $simulation.explosionForce, range: 0.5...3.0, format: "%.1fx")
                    NativeSliderRow(label: "Satellite Hitbox Size", value: $simulation.collisionRadius, range: 1.0...3.0, step: 0.1, format: "%.1f")
                    
                    NativeSliderRow(label: "Debris per Collision", value: $simulation.debrisPerCollision, range: 2...6, step: 1, format: "%.0f")
                    NativeSliderRow(label: "Max Debris Count", value: $simulation.maxDebris, range: 1000...3000, step: 100, format: "%.0f")
                    
                } header: {
                    Text("Real Time Physics")
                } footer: {
                    Text("Higher ejection forces will create larger clouds, and larger hitboxes will make satellites easier to hit.")
                }
                
                Section {
                    DisclosureGroup("Advanced Debris Spread") {
                        
                        VStack(alignment: .leading, spacing: 2) {
                            NativeSliderRow(label: "Tangential (Velocity)", value: $simulation.spreadTangential, range: 0.0...2.0)
                            Text("Stretches the cloud along the orbit.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            NativeSliderRow(label: "Radial (Altitude)", value: $simulation.spreadRadial, range: 0.0...2.0)
                            Text("Changes the apogee and perigee of the orbit.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            NativeSliderRow(label: "Normal (Inclination)", value: $simulation.spreadVertical, range: 0.0...2.0)
                            Text("Spreads debris sideways into new orbital planes.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                } footer: {
                    Text("Controls the shape of the debris cloud immediately after an explosion.")
                }
                
                Section {
                    Button("Reset Defaults") {
                        withAnimation { simulation.resetSettingsToDefaults() }
                    }
                    .foregroundStyle(.blue)
                    
                    Button(role: hasPendingChanges ? .none : .destructive) {
                        showRestartConfirmation = true
                    } label: {
                        if hasPendingChanges {
                            LabeledContent("Apply Changes & Restart") {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                        } else {
                            Text("Restart Simulation")
                        }
                    }
                    .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                        Button("Restart", role: .destructive) {
                            simulation.resetSimulation()
                        }
                    } message: {
                        Text(hasPendingChanges ? "Applying these changes will restart the simulation." : "This will reset all satellites and debris.")
                    }
                }
            }
            .navigationTitle("Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onClose() }.fontWeight(.semibold)
                }
            }
        }
    }
}

struct NativeSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double.Stride? = nil
    var format: String = "%.1f"
    var requiresRestart: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            LabeledContent(label) {
                HStack(spacing: 6) {
                    if requiresRestart {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2.weight(.bold))
                            .imageScale(.small)
                    }
                    Text(String(format: format, value))
                        .monospacedDigit()
                }
                .foregroundStyle(requiresRestart ? .orange : .secondary)
                .animation(.snappy, value: requiresRestart)
            }
            
            if let step = step {
                Slider(value: $value, in: range, step: step)
                    .accessibilityLabel(label)
                    .accessibilityValue(String(format: format, value))
            } else {
                Slider(value: $value, in: range)
                    .accessibilityLabel(label)
                    .accessibilityValue(String(format: format, value))
            }
        }
        .padding(.vertical, 4)
    }
}
