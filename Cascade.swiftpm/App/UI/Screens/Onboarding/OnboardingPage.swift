//
//  OnboardingPage.swift
//  Cascade
//

enum OnboardingPage: Int, CaseIterable {
    case intro
    case controls

    var next: OnboardingPage? { OnboardingPage(rawValue: rawValue + 1) }
    var previous: OnboardingPage? { OnboardingPage(rawValue: rawValue - 1) }

    var isLast: Bool { next == nil }
}
