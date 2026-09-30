//
//  ControlColumn.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct ControlColumn: View {
    let items: [ControlItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                if item.id != items.first?.id {
                    Divider().overlay(DesignTokens.hairline)
                }
                ControlRow(item: item)
                    .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
