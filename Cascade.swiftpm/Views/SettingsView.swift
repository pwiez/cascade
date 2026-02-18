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
                    Toggle("Disable Camera Movement", isOn: $simulation.isCameraLocked)
                    Toggle("Show Earth", isOn: $simulation.showEarth)
                    Toggle("Show Satellites", isOn: $simulation.showSatellites)
                    Toggle("Show Simulation Stats", isOn: $simulation.showStats)
                    
                    DisclosureGroup("Colors & Scaling") {
                        ColorPicker("Satellite Color", selection: $simulation.satelliteColor, supportsOpacity: false)
                        ColorPicker("Debris Color", selection: $simulation.debrisColor, supportsOpacity: false)
                        ColorPicker("Universe Color", selection: $simulation.backgroundColor, supportsOpacity: false)
                        
                        NativeSliderRow(label: "Satellite Scale", value: $simulation.satelliteScale, range: 0.5...5.0, format: "%.1fx")
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
                        Slider(value: $simulation.timeScale, in: 0.1...5.0, step: 0.1) {
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
                        range: 100...200,
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
                    
                    Toggle("Random Orbital Planes", isOn: $simulation.draft.useRandomInclination)
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
                    NativeSliderRow(label: "Debris Ejection Force", value: $simulation.explosionForce, range: 0.5...7.0, step: 0.5, format: "%.1fx")
                    NativeSliderRow(label: "Satellite Hitbox Size", value: $simulation.collisionRadius, range: 1.0...4.0, format: "%.1f")
                    
                    NativeSliderRow(label: "Debris per Collision", value: $simulation.draft.debrisPerCollision, range: 2...6, step: 1, format: "%.0f")
                    
                    NativeSliderRow(label: "Max Debris Count", value: $simulation.draft.maxDebris, range: 500...2500, step: 100, format: "%.0f")
                    
                } header: {
                    Text("Real Time Physics")
                } footer: {
                    Text("Higher ejection forces will create larger clouds, and larger hitboxes will make satellites easier to hit.")
                }
                
                Section {
                    DisclosureGroup("Advanced Debris Spread") {
                        NativeSliderRow(label: "Tangential (Velocity)", value: $simulation.spreadTangential, range: 0.0...2.0, step: 0.1)
                        
                        NativeSliderRow(label: "Radial (Altitude)", value: $simulation.spreadRadial, range: 0.0...2.0, step: 0.1)
                        
                        NativeSliderRow(label: "Normal (Inclination)", value: $simulation.spreadVertical, range: 0.0...2.0, step: 0.1)
                    }
                } footer: {
                    Text("Controls the shape of the debris cloud immediately after an explosion.\nTangential stretches the cloud along the orbit.\nRadial changes the apogee and perigee of the orbit.\nNormal spreads debris sideways into new orbital planes.")
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
    var step: Double.Stride = 0.1
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
            
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(label)
                .accessibilityValue(String(format: format, value))
        }
        .padding(.vertical, 4)
    }
}
