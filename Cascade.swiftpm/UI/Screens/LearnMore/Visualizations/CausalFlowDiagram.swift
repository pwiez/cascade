//
//  CausalFlowDiagram.swift
//  Cascade
//
//  Created by Pedro Wiezel on 16/02/26.
//

import SwiftUI

struct CausalFlowDiagram: View {
    private let steps: [(icon: String, color: Color, title: String)] = [
        ("cube.fill", .green, "Density of objects\nin orbit increases"),
        ("burst.fill", .orange, "A collision happens\nbetween them"),
        ("aqi.medium", .red, "Many new objects\nare created"),
        ("exclamationmark.triangle.fill", .yellow, "Collision risk\nincreases")
    ]

    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    node(icon: step.icon, color: step.color, title: step.title)

                    if index != steps.count - 1 {
                        Image(systemName: "chevron.compact.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DesignTokens.dimText)
                            .frame(width: 16)
                            .padding(.top, 12)
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.signal)
                Text("Each of these events feeds every other event!")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.mutedText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cascade loop diagram: increasing density leads to collisions, which create fragments, which escalate risk, which further increases density. The loop is self-reinforcing.")
    }

    private func node(icon: String, color: Color, title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
