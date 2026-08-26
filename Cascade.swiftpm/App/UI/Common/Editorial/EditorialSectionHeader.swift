import SwiftUI

/// A section heading within a chapter.
struct EditorialSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2.bold())
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
