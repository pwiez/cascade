//
//  TryThisBox.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/02/26.
//

import SwiftUI

struct TryThisBox: View {
    let title: String
    let instruction: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ThemedIcon(systemName: "slider.horizontal.3", color: .purple, isCircle: false)
            
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.purple)
                
                Text(instruction)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
            }
        }
        .padding(CascadeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(Color.purple.opacity(0.6), lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}
