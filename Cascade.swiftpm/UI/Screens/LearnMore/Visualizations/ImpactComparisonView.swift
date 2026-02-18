//
//  ImpactComparisonView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct ImpactComparisonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("ENERGY COMPARISON", systemImage: "bolt.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(white: 0.5))
            
            Text("Kinetic energy of a 1 cm aluminum sphere at orbital velocity, compared to familiar references.")
                .font(.caption)
                .foregroundStyle(.gray)
                .lineSpacing(3)
            
            VStack(spacing: 18) {
                EnergyBar(label: ".22 LR Bullet", energy: "~140 J", fraction: 0.004, color: Color.gray.opacity(0.5), highlight: false)
                EnergyBar(label: "Baseball Pitch", energy: "~155 J", fraction: 0.0044, color: Color.gray.opacity(0.5), highlight: false)
                EnergyBar(label: "9mm Bullet", energy: "~520 J", fraction: 0.015, color: Color.gray.opacity(0.6), highlight: false)
                EnergyBar(label: "1 cm Debris (7.5 km/s)", energy: "~35,000 J", fraction: 1.0, color: .orange, highlight: true)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text("A 1 cm fragment carries roughly **250×** the energy of a bullet.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }
}

struct EnergyBar: View {
    let label: String
    let energy: String
    let fraction: Double
    let color: Color
    let highlight: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(highlight ? .bold : .semibold))
                    .foregroundStyle(highlight ? .white : Color(white: 0.65))
                
                Spacer()
                
                Text(energy)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(highlight ? .orange : Color(white: 0.55))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.1))
                    
                    Capsule()
                        .fill(
                            highlight
                            ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(geo.size.width * fraction, 4))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(energy)")
    }
}