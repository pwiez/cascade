//
//  TimeSection.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI
import TipKit

struct TimeSection: View {
    @ObservedObject var simulation: Simulation
    
    private let timeTip = TimeScaleTip()
    
    var body: some View {
        Section(header: Text("Simulation Speed"), footer: Text("Controls the flow of time. Accelerate to watch debris clouds forming and the Earth rotating faster.")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.blue)
                    Text("Time Scale")
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.1fx", simulation.timeScale))
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $simulation.timeScale, in: 0.1...5.0, step: 0.1) {
                    Text("Time Scale")
                } minimumValueLabel: {
                    Image(systemName: "tortoise.fill").font(.caption2)
                } maximumValueLabel: {
                    Image(systemName: "hare.fill").font(.caption2)
                }
                .popoverTip(timeTip, arrowEdge: .bottom)
                .tint(.blue)
            }
            .padding(.vertical, 4)
        }
    }
}
