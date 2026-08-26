import SwiftUI

/// The iOS 26 Learn More layout, built on `NavigationSplitView`.
@available(iOS 26, *)
struct LearnMoreNativeView: View {
    @State private var activeSection: AppSection? = .hero

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $activeSection) {
                ForEach(AppSection.Group.allCases, id: \.self) { group in
                    Section {
                        ForEach(AppSection.sections(in: group)) { section in
                            NavigationLink(value: section) {
                                LearnMoreSidebarLabel(section: section)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Learn More")
            .listStyle(.sidebar)
        } detail: {
            if let activeSection {
                ChapterContainerView(activeSection: activeSection)
            } else {
                ContentUnavailableView(
                    "Select a Topic",
                    systemImage: "book.closed.fill",
                    description: Text("Choose a section from the sidebar to begin.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.chapterBackground.ignoresSafeArea())
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden)
    }
}
