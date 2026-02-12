//
//  PopulationSection.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI

struct PopulationSection: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        Section(header: Text("Active Satellites"), footer: Text("Satellite count is strictly capped to ensure 100% of debris can be rendered without deletions.")) {
            
            Toggle(isOn: $simulation.showSatellites) {
                HStack {
                    Image(systemName: simulation.showSatellites ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(.green)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol)))
                    Text("Show Satellites")
                }
            }
            
            Toggle(isOn: $simulation.useRandomInclination) {
                HStack {
                    Image(systemName: "angle")
                        .foregroundStyle(.green)
                    Text("Spawn at Random Inclinations")
                }
            }
            
            if !simulation.useRandomInclination {
                Text("Disabling random orbital inclination will line up all the satellites at the Equator, turning the debris cloud into a ring.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Satellite Count")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(simulation.satelliteCount))")
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(simulation.satelliteCount >= simulation.maxSafeSatellites ? .red : .secondary)
                }
                
                Slider(value: $simulation.satelliteCount, in: 10...max(10, simulation.maxSafeSatellites), step: 10)
                    .tint(.green)
                
                if simulation.maxSafeSatellites < 500 {
                    Text("Cap is low due to high collision multiplier.")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if simulation.satelliteCount > 2000 {
                    Text("High object count may affect framerate.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
