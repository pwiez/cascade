//
//  LearnMoreSidebarLabel.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct LearnMoreSidebarLabel: View {
    let section: AppSection

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.subheadline.weight(.medium))
                if let subtitle = section.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: section.icon)
        }
    }
}
