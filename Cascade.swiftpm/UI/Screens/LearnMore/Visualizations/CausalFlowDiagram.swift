//
//  CausalFlowDiagram.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct CausalFlowDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("THE CASCADE LOOP", systemImage: "point.3.filled.connected.trianglepath.dotted")
                .font(.caption.weight(.bold))
                .foregroundStyle(CascadeTheme.dimText)
                .tracking(0.6)
            
            HStack(spacing: 0) {
                flowNode(icon: "cube.fill", title: "Density\nIncreases", color: .blue)
                flowConnector
                flowNode(icon: "burst.fill", title: "Collision\nOccurs", color: .orange)
                flowConnector
                flowNode(icon: "aqi.medium", title: "Fragments\nSpread", color: .gray)
                flowConnector
                flowNode(icon: "exclamationmark.triangle.fill", title: "Risk\nEscalates", color: .red)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.turn.up.left")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
                Text("Each stage feeds the next — the loop is self-reinforcing above the critical threshold.")
                    .font(.caption)
                    .foregroundStyle(CascadeTheme.mutedText)
                    .lineSpacing(CascadeTheme.compactLineSpacing)
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cascade loop diagram: increasing density leads to collisions, which create fragments, which escalate risk, which further increases density. The loop is self-reinforcing.")
    }
    
    var flowConnector: some View {
        VStack {
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(width: 24)
    }
    
    func flowNode(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ThemedIcon(systemName: icon, color: color, shape: .circle)
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(CascadeTheme.raisedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.innerRadius))
    }
}