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

struct GuideRow: View {
    let number: String
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(CascadeTheme.iconBackgroundOpacity))
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
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.blue)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundStyle(.blue)
                    Text("Definition")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                        .tracking(0.5)
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
        .padding(CascadeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

struct KeyConceptBox: View {
    let title: String
    let bodyText: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ThemedIcon(systemName: icon, color: .green, isCircle: false)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(bodyText)
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
                .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

struct ThemedIcon: View {
    let systemName: String
    let color: Color
    var size: CGFloat = CascadeTheme.iconSize
    var isCircle: Bool = false
    
    var body: some View {
        Image(systemName: systemName)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(CascadeTheme.iconBackgroundOpacity))
            .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: CascadeTheme.iconRadius)))
    }
}

struct GlossaryItem: View {
    let term: String
    let definition: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.blue.opacity(0.6))
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(term)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                Text(definition)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
            }
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .combine)
    }
}
