import SwiftUI

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    @State private var showRestartConfirmation = false
    
    var hasPendingChanges: Bool {
        simulation.draft.satelliteCount != simulation.activeSatelliteCount ||
        simulation.draft.maxDebris != simulation.activeMaxDebris
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Visuals") {
                    Toggle(isOn: $simulation.isCameraLocked) {
                        Label("Reset & Freeze Camera", systemImage: "camera.metering.center.weighted")
                    }
                    .tint(.blue)
                    Toggle("High Contrast", isOn: $simulation.highContrast)
                    Toggle("Omni Light", isOn: $simulation.useOmniLight)
                    Toggle("Show Earth", isOn: $simulation.showEarth)
                    Toggle("Show Satellites", isOn: $simulation.showSatellites)
                    Toggle("Show Stats", isOn: $simulation.showStats)
                }
                
                Section("Time Control") {
                    HStack {
                        Image(systemName: "clock")
                        Text("Time Scale")
                        Spacer()
                        Text(String(format: "%.1fx", simulation.timeScale))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $simulation.timeScale, in: 1.0...10.0, step: 0.5) {
                        Text("Time Scale")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise.fill")
                    } maximumValueLabel: {
                        Image(systemName: "hare.fill")
                    }
                }
                
                Section(header: Text("Population & Generation"), footer: Text("Changes to these values require a simulation respawn.")) {
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Debris Limit")
                            Spacer()
                            Text("\(Int(simulation.draft.maxDebris))")
                                .foregroundStyle(hasPendingChanges ? .orange : .secondary)
                                .bold(hasPendingChanges)
                        }
                        Slider(value: $simulation.draft.maxDebris, in: 500.0...5000.0, step: 100.0)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Debris Per Crash")
                            Spacer()
                            Text("\(Int(simulation.draft.debrisPerCollision))")
                                .foregroundStyle(hasPendingChanges ? .orange : .secondary)
                                .bold(hasPendingChanges)
                        }
                        Slider(value: $simulation.draft.debrisPerCollision, in: 3.0...7.0, step: 1.0)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Initial Satellites")
                            Spacer()
                            Text("\(Int(simulation.draft.satelliteCount))")
                                .foregroundStyle(hasPendingChanges ? .orange : .secondary)
                                .bold(hasPendingChanges)
                        }
                        Slider(value: $simulation.draft.satelliteCount, in: 0.0...1000.0, step: 25.0)
                    }
                }
                
                Section("Physics Parameters") {
                    row(label: "Explosion Force", value: $simulation.explosionForce, range: 1.0...10.0, fmt: "%.1f")
                    row(label: "Hitbox Size", value: $simulation.collisionRadius, range: 1.0...5.0, fmt: "%.1f")
                }
                
                Section {
                    Button("Reset Defaults") {
                        simulation.resetSettingsToDefaults()
                    }
                    
                    Button(role: hasPendingChanges ? .none : .destructive) {
                        showRestartConfirmation = true
                    } label: {
                        if hasPendingChanges {
                            HStack {
                                Text("Apply Changes & Respawn")
                                Spacer()
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .foregroundStyle(.orange)
                        } else {
                            Text("Respawn Simulation")
                        }
                    }
                    .confirmationDialog("Reset?", isPresented: $showRestartConfirmation) {
                        Button("Respawn", role: .destructive) { simulation.resetSimulation() }
                    }
                }
            }
            .navigationTitle("Parameters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func row(label: String, value: Binding<Double>, range: ClosedRange<Double>, fmt: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: fmt, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
}
