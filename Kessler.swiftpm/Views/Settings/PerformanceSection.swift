//
//  PerformanceSection.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI

struct PerformanceSection: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        Section(header: Text("Performance Limit"), footer: Text("Capping the debris count prevents the simulation from lagging on older devices. Excess debris will be automatically removed.")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(.red)
                    Text("Max Debris Limit")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(simulation.maxDebris))")
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $simulation.maxDebris, in: 500...7000, step: 100)
                    .tint(.red)
                
                if simulation.maxDebris > 5000 {
                    Text("Warning: High object counts may reduce frame rate.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
        }
    }
}