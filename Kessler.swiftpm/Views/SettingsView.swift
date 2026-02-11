import SwiftUI

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Simulation Speed")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Time Scale")
                            Spacer()
                            Text(String(format: "%.1fx", simulation.timeScale))
                                .bold().monospacedDigit()
                        }
                        Slider(value: $simulation.timeScale, in: 0.1...5.0, step: 0.1)
                        
                        HStack {
                            Text("Slow").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("Fast").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Initial Population"), footer: Text("Requires respawn to take effect.")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "satellite.fill")
                            Text("LEO Satellites")
                            Spacer()
                            Text("\(Int(simulation.leoCount))")
                                .bold()
                                .monospacedDigit()
                                .foregroundStyle(simulation.leoCount > 2000 ? .orange : .primary)
                        }
                        Slider(value: $simulation.leoCount, in: 100...5000, step: 100)
                    }
                }
                
                Section(header: Text("Collision Physics")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Debris per Crash")
                            Spacer()
                            Text("\(Int(simulation.debrisPerCrash))").bold().monospacedDigit()
                        }
                        Slider(value: $simulation.debrisPerCrash, in: 1...30, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Explosion Force")
                            Spacer()
                            Text(String(format: "%.1f", simulation.explosionForce)).bold().monospacedDigit()
                        }
                        Slider(value: $simulation.explosionForce, in: 0.1...10.0, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Hitbox Size")
                            Spacer()
                            Text(String(format: "%.1f km", simulation.collisionRadius)).bold().monospacedDigit()
                        }
                        Slider(value: $simulation.collisionRadius, in: 0.5...5.0, step: 0.1)
                    }
                }
                
                Section(header: Text("Debris Distribution"), footer: Text("Controls how debris spreads after a collision.")) {
                    
                    VStack(alignment: .leading) {
                        Text("Tangential (Velocity)").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "arrow.left.and.right")
                            Slider(value: $simulation.spreadTangential, in: 0.1...5.0)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Vertical (Inclination)").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "arrow.up.and.down")
                            Slider(value: $simulation.spreadVertical, in: 0.1...5.0)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Radial (Altitude)").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "circle.circle")
                            Slider(value: $simulation.spreadRadial, in: 0.1...5.0)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                        simulation.resetSimulation()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                            Text("Respawn Simulation")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Parameters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
