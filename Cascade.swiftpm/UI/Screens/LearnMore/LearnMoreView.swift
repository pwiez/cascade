//
//  AppSection.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case hero = "Intro"
    case orbits = "01. How Orbits Work"
    case mechanics = "02. The Cascade Effect"
    case situation = "03. The Situation"
    case remediation = "04. Remediation"
    case glossary = "05. Glossary"
    case about = "06. About"
    case credits = "07. Credits"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .hero: return "What is Kessler Syndrome?"
        case .orbits: return "How Orbits Work"
        case .mechanics: return "Chain Reaction"
        case .situation: return "Current Situation"
        case .remediation: return "Remediation"
        case .glossary: return "Glossary"
        case .about: return "About Cascade"
        case .credits: return "Sources & Credits"
        }
    }
    
    var subtitle: String {
        switch self {
        case .hero: return "A developing threat"
        case .orbits: return "Falling but missing the ground"
        case .mechanics: return "The physics of crashes in space"
        case .situation: return "Where we stand today"
        case .remediation: return "Is it possible to clean up space?"
        case .glossary: return ""
        case .about: return ""
        case .credits: return ""
        }
    }
    
    var icon: String {
        switch self {
        case .hero: return "globe.americas.fill"
        case .orbits: return "arrow.triangle.swap"
        case .mechanics: return "arrow.3.trianglepath"
        case .situation: return "clock.arrow.circlepath"
        case .remediation: return "wrench.and.screwdriver.fill"
        case .glossary: return "text.book.closed.fill"
        case .about: return "info.circle.fill"
        case .credits: return "books.vertical.fill"
        }
    }
}

struct LearnMoreView: View {
    @State private var activeSection: AppSection? = .hero
    
    var body: some View {
        NavigationSplitView() {
            List(selection: $activeSection) {
                Section {
                    ForEach(AppSection.allCases.prefix(5)) { section in
                        sidebarLink(for: section)
                    }
                }
 
                Section {
                    ForEach(AppSection.allCases.dropFirst(5)) { section in
                        sidebarLink(for: section)
                    }
                }
            }
            .navigationTitle("Learn More")
            .listStyle(.sidebar)
        } detail: {
            if let section = activeSection {
                ChapterContainerView(activeSection: section)
            } else {
                ContentUnavailableView("Select a Topic", systemImage: "book.closed.fill", description: Text("Choose a section from the sidebar to begin."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden)
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func sidebarLink(for section: AppSection) -> some View {
        NavigationLink(value: section) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.subheadline.weight(.medium))
                    if !section.subtitle.isEmpty {
                        Text(section.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: section.icon)
            }
        }
    }
}

struct ChapterContainerView: View {
    let activeSection: AppSection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(activeSection.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    
                    if !activeSection.subtitle.isEmpty {
                        Text(activeSection.subtitle)
                            .font(.title2)
                            .foregroundStyle(CascadeTheme.dimText)
                    }
                    
                    Divider().overlay(.white)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                }
                .accessibilityAddTraits(.isHeader)
                .accessibilityElement(children: .combine)
                
                Group {
                    switch activeSection {
                    case .hero:        OverviewChapter()
                    case .orbits:      OrbitsChapter()
                    case .mechanics:   MechanicsChapter()
                    case .situation:   SituationChapter()
                    case .remediation: RemediationChapter()
                    case .glossary:    GlossaryChapter()
                    case .about:       AboutChapter()
                    case .credits:     CreditsChapter()
                    }
                }
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .id(activeSection.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
