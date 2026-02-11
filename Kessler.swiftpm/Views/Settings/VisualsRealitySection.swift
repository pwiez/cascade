//
//  VisualsRealitySection.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI
import TipKit

struct VisualsRealitySection: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        
        Section(header: Text("Visuals & Reality")) {
            
            Toggle(isOn: $simulation.useOmniLight) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.yellow)
                    Text("Omnidirectional Light")
                }
                Text("Adds another light source behind the Earth when activated, so debris and satellites can be seen at all times.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "circle.circle.fill")
                        .foregroundStyle(.purple)
                    Text("Satellite Size")
                    Spacer()
                    Text(String(format: "%.1fx", simulation.satelliteScale))
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $simulation.satelliteScale, in: 0.5...5.0, step: 0.5)
                    .tint(.purple)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.gray)
                    Text("Debris Size")
                    Spacer()
                    Text(String(format: "%.1fx", simulation.debrisScale))
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $simulation.debrisScale, in: 0.5...5.0, step: 0.5)
                    .tint(.gray)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "arrow.down.to.line.compact")
                        .foregroundStyle(.blue)
                    Text("Gravity Force")
                    Spacer()
                    Text(String(format: "%.1fx", simulation.gravityMultiplier))
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $simulation.gravityMultiplier, in: 0.1...3.0, step: 0.1)
                    .tint(.blue)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "arrow.up.and.down.circle")
                        .foregroundStyle(.cyan)
                    Text("Spawn Altitude")
                    Spacer()
                    Text("\(Int(simulation.orbitAltitude)) km")
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $simulation.orbitAltitude, in: 105...200, step: 5)
                    .tint(.cyan)
            }
            Text("Changing spawn altitude requires a Respawn to take effect.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
