//
//  PageDots.swift
//  Cascade
//
//  Created by Pedro Wiezel on 27/05/26.
//

import SwiftUI

struct PageDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index == current ? 1 : 0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(total)")
    }
}
