//
//  AppSection.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case hero = "Intro"
    case mechanics = "01. Mechanics"
    case situation = "02. The Situation"
    case remediation = "03. Remediation"
    case about = "04. About"
    case credits = "05. Credits"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .hero: return "What is Kessler Syndrome?"
        case .mechanics: return "Orbital Mechanics"
        case .situation: return "Current Situation"
        case .remediation: return "Remediation"
        case .about: return "About Cascade"
        case .credits: return "Sources & Credits"
        }
    }
    
    var subtitle: String {
        switch self {
        case .hero: return "A cascading threat to space exploration"
        case .mechanics: return "Physics of orbital collisions"
        case .situation: return "Where we stand today"
        case .remediation: return "Strategies to mitigate the situation"
        case .about: return "How this app approaches the subject"
        case .credits: return ""
        }
    }
    
    var icon: String {
        switch self {
        case .hero: return "globe.americas.fill"
        case .mechanics: return "arrow.3.trianglepath"
        case .situation: return "clock.arrow.circlepath"
        case .remediation: return "wrench.and.screwdriver.fill"
        case .about: return "info.circle.fill"
        case .credits: return "books.vertical.fill"
        }
    }
}

struct LearnMoreView: View {
    @State private var activeSection: AppSection? = .hero
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $activeSection) {
                ForEach(AppSection.allCases) { section in
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
            .navigationTitle("Learn More")
            .listStyle(.sidebar)
            .toolbar(removing: .sidebarToggle)
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
        .onChange(of: columnVisibility) { _, _ in
            columnVisibility = .all
        }
        .toolbar(.hidden)
        .preferredColorScheme(.dark)
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
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .accessibilityAddTraits(.isHeader)
                .accessibilityElement(children: .combine)
                
                Group {
                    switch activeSection {
                    case .hero:        OverviewChapter()
                    case .mechanics:   MechanicsChapter()
                    case .situation:   SituationChapter()
                    case .remediation: RemediationChapter()
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
