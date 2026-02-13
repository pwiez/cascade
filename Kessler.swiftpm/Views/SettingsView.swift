import SwiftUI

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    @State private var showRestartConfirmation = false
    
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
                
                Section("Population Limits") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Debris")
                            Spacer()
                            Text("\(Int(simulation.maxDebris))").foregroundStyle(.secondary)
                        }
                        Slider(value: $simulation.maxDebris, in: 500...3000, step: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Satellites")
                            Spacer()
                            Text("\(Int(simulation.satelliteCount))").foregroundStyle(.secondary)
                        }
                        Slider(value: $simulation.satelliteCount, in: 10...500, step: 10)
                    }
                }
                
                Section("Physics Parameters") {
                    row(label: "Explosion Force", value: $simulation.explosionForce, range: 0.1...10.0, fmt: "%.1f")
                    row(label: "Debris Per Hit", value: $simulation.debrisPerCollision, range: 1...30, fmt: "%.0f")
                    row(label: "Hitbox Size", value: $simulation.collisionRadius, range: 0.5...5.0, fmt: "%.1f")
                }
                
                Section {
                    Button("Reset Defaults") {
                        simulation.resetSettingsToDefaults()
                    }
                    
                    Button("Respawn Simulation", role: .destructive) {
                        showRestartConfirmation = true
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
