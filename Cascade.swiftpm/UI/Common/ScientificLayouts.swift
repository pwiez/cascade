//
//  ScientificLayouts.swift
//  Cascade
//
//  Created by Pedro Wiezel on 25/02/26.
//

import SwiftUI

struct ScientificCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        DataPanel { content }
    }
}

struct TextParagraph: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        Text(text)
            .font(.body)
            .lineSpacing(DesignTokens.bodyLineSpacing)
            .foregroundStyle(DesignTokens.bodyText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct GuideRow: View {
    let number: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(DesignTokens.iconBackgroundOpacity))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct DefinitionCallout: View {
    let term: String
    let definition: String
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Kicker(text: "Definition", color: DesignTokens.signal)

            Text(term)
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)

            Text(definition)
                .font(.title3.weight(.regular))
                .foregroundStyle(DesignTokens.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(source)")
                .font(.caption.italic())
                .foregroundStyle(DesignTokens.mutedText)
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }
}

struct KeyConceptBox: View {
    let title: String
    let bodyText: String
    let icon: String

    var body: some View {
        RuledCallout(label: "Key Concept") {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
    }
}

struct GlossaryItem: View {
    let term: String
    let definition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(DesignTokens.hairline)
                .frame(height: 1)

            Text(term)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(definition)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
        .accessibilityElement(children: .combine)
    }
}

struct TryThisBox: View {
    let instruction: String

    var body: some View {
        RuledCallout(label: "Try It", accent: DesignTokens.signal, labelColor: DesignTokens.signal) {
            Text(instruction)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
    }
}
