//
//  OrbitalStatus.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct SimulationMetrics: View {
    @ObservedObject var telemetry: Telemetry
    let initialSatellites: Int
    let satelliteColor: Color
    let debrisColor: Color
    
    private var stats: SimStats { telemetry.stats }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                metricColumn(
                    title: "Satellites",
                    value: stats.satellites,
                    color: satelliteColor
                )
                
                Spacer()
                
                Divider().cascadeDivider()
                    .frame(height: 32)
                
                Spacer()
                
                metricColumn(
                    title: "Debris",
                    value: stats.debris,
                    color: debrisColor
                )
            }
        }
        .padding()
        .frame(width: 240)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func metricColumn(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value.formatted())
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
        .frame(minWidth: 80, alignment: .leading)
    }
}
