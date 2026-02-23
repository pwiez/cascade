//
//  OrbitalStatus.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

enum OrbitalStatus: String {
    case stable = "Stable"
    case warning = "Collisions Active"
    case danger = "Cascade Developing"
    case critical = "Orbit Compromised"

    var tint: Color {
        switch self {
        case .stable: return .green
        case .warning: return .yellow
        case .danger: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .stable: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "exclamationmark.arrow.triangle.2.circlepath"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    static func evaluate(current: Int, initial: Int) -> OrbitalStatus {
        guard initial > 0 else { return .stable }
        
        if current >= initial { return .stable }
        
        let ratio = Double(current) / Double(initial)
        
        if ratio < 0.35 { return .critical }
        
        if ratio < 0.75 { return .danger }
        
        return .warning
    }
}

struct SimulationMetrics: View {
    @ObservedObject var telemetry: Telemetry
    let initialSatellites: Int
    let satelliteColor: Color
    let debrisColor: Color

    private var stats: SimStats { telemetry.stats }

    private var status: OrbitalStatus {
        OrbitalStatus.evaluate(current: stats.satellites, initial: initialSatellites)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                Text(status.rawValue)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(status.tint)
            .accessibilityElement(children: .combine)

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
        .padding(18)
        .frame(width: 240)
        .glassEffect(in: .rect(cornerRadius: 12))
        .animation(.snappy, value: status)
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
