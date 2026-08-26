//
//  ChapterContainerView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct ChapterContainerView: View {
    let activeSection: AppSection

    @State private var scrollPosition = ScrollPosition(edge: .top)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header

                switch activeSection {
                case .hero: IntroChapter()
                case .orbits: OrbitPhysicsChapter()
                case .mechanics: MechanicsChapter()
                case .situation: SituationChapter()
                case .remediation: RemediationChapter()
                case .glossary: GlossaryChapter()
                case .about: AboutChapter()
                case .credits: CreditsChapter()
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollPosition($scrollPosition)
        .onChange(of: activeSection) { _, _ in
            scrollPosition.scrollTo(edge: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(activeSection.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = activeSection.subtitle {
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(DesignTokens.dimText)
            }

            Rectangle()
                .fill(DesignTokens.ruleStrong)
                .frame(height: 1)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
