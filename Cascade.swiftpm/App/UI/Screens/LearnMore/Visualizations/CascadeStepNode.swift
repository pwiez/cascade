//
//  CascadeStepNode.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct CascadeStepNode: View {
    let step: CascadeStep

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: step.icon)
                .font(.title3)
                .foregroundStyle(step.color)

            Text(step.title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
