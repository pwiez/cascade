import SwiftUI

struct Kicker: View {
    let text: String
    var color: Color = DesignTokens.dimText

    var body: some View {
        Text(text)
            .font(.system(.footnote).smallCaps().weight(.semibold))
            .tracking(1.0)
            .foregroundStyle(color)
    }
}

struct EditorialSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct RuledCallout<Content: View>: View {
    let label: String
    var accent: Color = DesignTokens.ruleStrong
    var labelColor: Color = DesignTokens.dimText
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            RoundedRectangle(cornerRadius: 1)
                .fill(accent)
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: label, color: labelColor)
                content
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DataPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .padding(.vertical, DesignTokens.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.dataSurface)
        .overlay(alignment: .top) {
            Rectangle().fill(DesignTokens.ruleStrong).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.ruleStrong).frame(height: 1)
        }
    }
}
