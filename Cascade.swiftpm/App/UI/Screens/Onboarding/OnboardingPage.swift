//
//  OnboardingPage.swift
//  Cascade
//

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case intro
    case controls

    var id: Int { rawValue }

    var next: OnboardingPage? { OnboardingPage(rawValue: rawValue + 1) }
    var previous: OnboardingPage? { OnboardingPage(rawValue: rawValue - 1) }

    var isLast: Bool { next == nil }
}
