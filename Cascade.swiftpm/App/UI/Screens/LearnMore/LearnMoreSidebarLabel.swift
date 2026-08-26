import SwiftUI

/// A chapter's icon, title and subtitle, as shown in the sidebar.
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
