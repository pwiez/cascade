//
//  LearnMoreLegacyView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 28/05/26.
//

import SwiftUI

struct LearnMoreLegacyView: View {
    @State private var activeSection: AppSection = .hero

    private let sidebarWidth: CGFloat = 320

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: sidebarWidth)
                .background(DesignTokens.sidebarBackground.ignoresSafeArea())

            Rectangle()
                .fill(DesignTokens.hairline)
                .frame(width: 1)
                .ignoresSafeArea()

            ChapterContainerView(activeSection: activeSection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.chapterBackground.ignoresSafeArea())
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Learn More")
                    .font(.largeTitle.bold())
                    .padding(.top, 28)
                    .padding(.horizontal, 20)
                    .accessibilityAddTraits(.isHeader)

                ForEach(Array(AppSection.Group.allCases.enumerated()), id: \.element) { index, group in
                    if index != 0 {
                        Rectangle()
                            .fill(DesignTokens.hairline)
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }

                    VStack(spacing: 2) {
                        ForEach(AppSection.sections(in: group)) { section in
                            LearnMoreSidebarRow(
                                section: section,
                                isActive: activeSection == section,
                                action: { activeSection = section }
                            )
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
