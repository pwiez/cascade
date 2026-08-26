//
//  LearnMoreSidebarRow.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct LearnMoreSidebarRow: View {
    let section: AppSection
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LearnMoreSidebarLabel(section: section)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    .white.opacity(isActive ? 0.08 : 0),
                    in: .rect(cornerRadius: 10)
                )
                .contentShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
