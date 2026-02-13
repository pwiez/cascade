import SwiftUI
import TipKit

struct UnifiedSettingsView: View {
    @ObservedObject var simulation: Simulation
    @Binding var isPresented: Bool
    
    @State private var showRestartConfirmation = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                Spacer().frame(height: 60)
                
                HStack {
                    Text("Parameters")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal)
                
                GlassSection(header: "TIME CONTROL") {
                    HStack {
                        Label("Time Scale", systemImage: "clock")
                        Spacer()
                        Text(String(format: "%.1fx", simulation.timeScale))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "tortoise.fill").font(.caption).foregroundStyle(.secondary)
                        Slider(value: $simulation.timeScale, in: 0.1...5.0, step: 0.1)
                        Image(systemName: "hare.fill").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                GlassSection(header: "PERFORMANCE", footer: "Lower this limit if the frame rate drops.") {
                    HStack {
                        Label("Max Debris", systemImage: "cpu")
                        Spacer()
                        Text("\(Int(simulation.maxDebris))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    Slider(value: $simulation.maxDebris, in: 500...3000, step: 100) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("500").font(.caption2).foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("3k").font(.caption2).foregroundStyle(.secondary)
                    }
                    .tint(simulation.maxDebris > 2500 ? .orange : .green)
                }
                
                GlassSection(header: "SATELLITES") {
                    Toggle("Show Satellites", isOn: $simulation.showSatellites)
                    
                    Divider()
                    
                    Toggle("Random Inclination", isOn: $simulation.useRandomInclination)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Count")
                            Spacer()
                            Text("\(Int(simulation.satelliteCount))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $simulation.satelliteCount, in: 10...max(10, simulation.maxSafeSatellites), step: 10)
                    }
                }
                
                GlassSection(header: "PHYSICS") {
                    LabeledSlider(label: "Explosion Force", value: $simulation.explosionForce, range: 0.1...10.0, format: "%.1f")
                    
                    Divider()
                    
                    LabeledSlider(label: "Debris Created", value: $simulation.debrisPerCollision, range: 1...30, format: "%.0f")
                    
                    Divider()
                    
                    LabeledSlider(label: "Hitbox Size", value: $simulation.collisionRadius, range: 0.5...5.0, format: "%.1f km")
                }
                
                GlassSection(header: "VISUALS") {
                    Toggle("Omni Light", isOn: $simulation.useOmniLight)
                    
                    Divider()
                    
                    LabeledSlider(label: "Sat Size", value: $simulation.satelliteScale, range: 0.5...5.0, format: "%.1fx")
                    
                    Divider()
                    
                    LabeledSlider(label: "Debris Size", value: $simulation.debrisScale, range: 0.5...5.0, format: "%.1fx")
                }
                
                VStack(spacing: 12) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        simulation.resetSettingsToDefaults()
                    } label: {
                        Text("Reset Defaults")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(role: .destructive) {
                        showRestartConfirmation = true
                    } label: {
                        Text("Respawn Simulation")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                        Button("Respawn", role: .destructive) {
                            simulation.resetSimulation()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct GlassSection<Content: View>: View {
    let header: String
    var footer: String? = nil
    let content: Content
    
    init(header: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
            
            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if let footer = footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 0.1)
        }
    }
}
