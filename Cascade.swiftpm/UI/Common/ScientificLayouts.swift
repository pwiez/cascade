//
//  ScientificCard.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct ScientificCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content.padding(CascadeTheme.cardPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
        )
    }
}

struct TextParagraph: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.body)
            .lineSpacing(CascadeTheme.bodyLineSpacing)
            .foregroundStyle(CascadeTheme.bodyText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.blue)
            .tracking(1.2)
            .accessibilityAddTraits(.isHeader)
    }
}

struct GuideRow: View {
    let number: String
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(CascadeTheme.iconBackgroundOpacity))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(CascadeTheme.compactLineSpacing)
        }
    }
}

struct DefinitionCallout: View {
    let term: String
    let definition: String
    let source: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.blue)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundStyle(.blue)
                    Text("Definition")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                }
                
                Text(term)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                Text(definition)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
                
                Text("— \(source)")
                    .font(.caption.italic())
                    .foregroundStyle(CascadeTheme.mutedText)
            }
            .padding(.vertical, 4)
        }
        .cascadeAccentCard(.blue)
        .accessibilityElement(children: .combine)
    }
}

struct KeyConceptBox: View {
    let title: String
    let bodyText: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ThemedIcon(systemName: icon, color: .orange, shape: .roundedRect)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
            }
        }
        .cascadeAccentCard(.orange)
        .accessibilityElement(children: .combine)
    }
}
