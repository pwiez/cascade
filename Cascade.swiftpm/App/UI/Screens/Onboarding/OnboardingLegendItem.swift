//
//  OnboardingLegendItem.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct OnboardingLegendItem: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 34

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(color)
                .frame(width: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
