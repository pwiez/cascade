//
//  AppSection.swift
//  Cascade
//

enum AppSection: String, CaseIterable, Identifiable {
    case hero
    case orbits
    case mechanics
    case situation
    case remediation
    case glossary
    case about
    case credits

    var id: String { rawValue }

    enum Group: CaseIterable {
        case chapters
        case reference
    }

    var group: Group {
        switch self {
        case .hero, .orbits, .mechanics, .situation, .remediation: .chapters
        case .glossary, .about, .credits: .reference
        }
    }

    static func sections(in group: Group) -> [AppSection] {
        allCases.filter { $0.group == group }
    }

    var title: String {
        switch self {
        case .hero: "What is Kessler Syndrome?"
        case .orbits: "How Orbits Work"
        case .mechanics: "Chain Reaction"
        case .situation: "Current Situation"
        case .remediation: "Remediation"
        case .glossary: "Glossary"
        case .about: "About Cascade"
        case .credits: "Sources & Credits"
        }
    }

    var subtitle: String? {
        switch self {
        case .orbits: "The art of falling and missing the ground"
        case .mechanics: "The physics of crashes in space"
        case .situation: "Where we are today"
        case .remediation: "Is it possible to clean up an orbit?"
        case .hero, .glossary, .about, .credits: nil
        }
    }

    var icon: String {
        switch self {
        case .hero: "globe.americas.fill"
        case .orbits: "arrow.triangle.swap"
        case .mechanics: "arrow.3.trianglepath"
        case .situation: "clock.arrow.circlepath"
        case .remediation: "wrench.and.screwdriver.fill"
        case .glossary: "text.book.closed.fill"
        case .about: "info.circle.fill"
        case .credits: "books.vertical.fill"
        }
    }
}
