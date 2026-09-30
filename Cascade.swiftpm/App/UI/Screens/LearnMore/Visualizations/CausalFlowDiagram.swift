//
//  CausalFlowDiagram.swift
//  Cascade
//
//  Created by Pedro Wiezel on 16/02/26.
//

import SwiftUI

struct CausalFlowDiagram: View {
    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(CascadeStep.all) { step in
                    CascadeStepNode(step: step)

                    if step.id != CascadeStep.all.last?.id {
                        Image(systemName: "chevron.compact.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DesignTokens.dimText)
                            .frame(width: 16)
                            .padding(.top, 12)
                    }
                }
            }

            Label("Each of these events feeds every other event!", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(DesignTokens.mutedText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cascade loop diagram: increasing density leads to collisions, which create fragments, which escalate risk, which further increases density. The loop is self-reinforcing.")
    }
}
