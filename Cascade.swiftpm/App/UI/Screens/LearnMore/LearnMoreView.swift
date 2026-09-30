//
//  LearnMoreView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 12/02/26.
//

import SwiftUI

struct LearnMoreView: View {
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
