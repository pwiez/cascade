//
//  ControlRow.swift
//  Cascade
//
//  Created by Pedro Wiezel on 27/05/26.
//

import SwiftUI

struct ControlRow: View {
    let item: ControlItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: item.icon)
                .font(.body)
                .foregroundStyle(item.tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
