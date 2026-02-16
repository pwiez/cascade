import SwiftUI

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    var onClose: () -> Void
    
    @State private var showRestartConfirmation = false
    
    var hasPendingChanges: Bool {
        simulation.draft.satelliteCount != simulation.activeSatelliteCount ||
        simulation.draft.maxDebris != simulation.activeMaxDebris
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section {
                    Toggle(isOn: $simulation.isCameraLocked) {
                        Label("Reset & Freeze Camera", systemImage: "camera.metering.center.weighted")
                    }
                    .tint(.blue)
                     Toggle(isOn: $simulation.highContrast) {
                        Label("High Contrast Mode", systemImage: "circle.lefthalf.filled")
                    }
                    Toggle(isOn: $simulation.useOmniLight) {
                        Label("Omni Light (Fill)", systemImage: "lightbulb.max")
                    }
                    Toggle(isOn: $simulation.showEarth) {
                        Label("Show Earth", systemImage: "globe.americas.fill")
                    }
                    Toggle(isOn: $simulation.showSatellites) {
                        Label("Show Satellites", systemImage: "satellite.fill")
                    }
                    Toggle(isOn: $simulation.showStats) {
                        Label("Show HUD Stats", systemImage: "chart.bar.fill")
                    }
                    Group {
                        row(icon: "maximize", color: .green, label: "Sat Scale", value: $simulation.satelliteScale, range: 0.5...5.0, fmt: "%.1f")
                        row(icon: "smallcircle.filled.circle", color: .red, label: "Debris Scale", value: $simulation.debrisScale, range: 0.5...5.0, fmt: "%.1f")
                    }
                } header: { Text("Visual Configuration") }

                Section {
                    HStack {
                        Image(systemName: "clock").foregroundStyle(.blue)
                        Text("Time Scale")
                        Spacer()
                        Text(String(format: "%.1fx", simulation.timeScale)).foregroundStyle(.secondary)
                    }
                    TickSlider(value: $simulation.timeScale, range: 1.0...10.0, step: 0.5, minimumIcon: "tortoise.fill", maximumIcon: "hare.fill")
                } header: { Text("Simulation Speed") }

                Section {
                    row(icon: "arrow.down.to.line.compact", color: .gray, label: "Gravity Multiplier", value: $simulation.gravityMultiplier, range: 0.1...3.0, fmt: "%.1f")
                    row(icon: "arrow.up.and.down.circle", color: .blue, label: "Orbit Altitude", value: $simulation.orbitAltitude, range: 80.0...200.0, fmt: "%.0f")
                    row(icon: "burst.fill", color: .red, label: "Explosion Force", value: $simulation.explosionForce, range: 1.0...10.0, fmt: "%.1f")
                    row(icon: "scope", color: .orange, label: "Hitbox Size", value: $simulation.collisionRadius, range: 1.0...5.0, fmt: "%.1f")
                } header: { Text("Orbital Physics") }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        row(icon: "arrow.left.and.right", color: .purple, label: "Tangential Spread", value: $simulation.spreadTangential, range: 0.1...5.0, fmt: "%.1f")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        row(icon: "arrow.up.and.down", color: .green, label: "Vertical Spread", value: $simulation.spreadVertical, range: 0.1...5.0, fmt: "%.1f")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        row(icon: "arrow.up.left.and.arrow.down.right", color: .cyan, label: "Radial Spread", value: $simulation.spreadRadial, range: 0.1...3.0, fmt: "%.1f")
                    }
                } header: { Text("Debris Scatter Logic") }

                Section {
                    Toggle(isOn: $simulation.useRandomInclination) { Label("Random Inclination", systemImage: "lines.measurement.horizontal") }
                    VStack(alignment: .leading) {
                        HStack { Label("Max Debris Limit", systemImage: "aqi.medium"); Spacer(); Text("\(Int(simulation.draft.maxDebris))").foregroundStyle(hasPendingChanges ? .orange : .secondary).bold(hasPendingChanges) }
                        Slider(value: $simulation.draft.maxDebris, in: 500.0...5000.0, step: 100.0)
                    }
                    VStack(alignment: .leading) {
                        HStack { Label("Debris Per Crash", systemImage: "sparkles"); Spacer(); Text("\(Int(simulation.draft.debrisPerCollision))").foregroundStyle(hasPendingChanges ? .orange : .secondary).bold(hasPendingChanges) }
                        Slider(value: $simulation.draft.debrisPerCollision, in: 3.0...7.0, step: 1.0)
                    }
                    VStack(alignment: .leading) {
                        HStack { Label("Initial Satellites", systemImage: "dot.radiowaves.up.forward"); Spacer(); Text("\(Int(simulation.draft.satelliteCount))").foregroundStyle(hasPendingChanges ? .orange : .secondary).bold(hasPendingChanges) }
                        Slider(value: $simulation.draft.satelliteCount, in: 0.0...1000.0, step: 25.0)
                    }
                } header: { Text("Population & Generation") }

                Section {
                    Button { withAnimation { simulation.resetSettingsToDefaults() } } label: { Label("Reset Defaults", systemImage: "arrow.counterclockwise") }
                    Button(role: hasPendingChanges ? .none : .destructive) { showRestartConfirmation = true } label: {
                        if hasPendingChanges { HStack { Text("Apply Changes & Respawn"); Spacer(); Image(systemName: "arrow.triangle.2.circlepath") }.foregroundStyle(.orange) } else { Text("Respawn Simulation") }
                    }
                    .confirmationDialog("Reset?", isPresented: $showRestartConfirmation) { Button("Respawn", role: .destructive) { simulation.resetSimulation() } }
                }
            }
            .navigationTitle("Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onClose()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    @ViewBuilder
    private func row(icon: String, color: Color, label: String, value: Binding<Double>, range: ClosedRange<Double>, fmt: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Label { Text(label) } icon: { Image(systemName: icon).foregroundStyle(color) }
                Spacer()
                Text(String(format: fmt, value.wrappedValue)).foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
}

struct TickSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let minimumIcon: String
    let maximumIcon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: minimumIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(0..<numberOfSteps(), id: \.self) { index in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 4)
                            if index != numberOfSteps() - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    Slider(value: $value, in: range, step: step)
                }
                
                Image(systemName: maximumIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func numberOfSteps() -> Int {
        let count = Int((range.upperBound - range.lowerBound) / step) + 1
        return max(0, count)
    }
}
