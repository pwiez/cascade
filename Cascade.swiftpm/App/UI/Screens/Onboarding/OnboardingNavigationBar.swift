//
//  OnboardingNavigationBar.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct OnboardingNavigationBar: View {
    let page: OnboardingPage
    let onBack: () -> Void
    let onAdvance: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                if page.previous != nil {
                    Button("Back", systemImage: "chevron.left", action: onBack)
                        .controlSize(.large)
                        .applyGlassStyle(isProminent: false, tint: nil)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)

            PageDots(current: page.rawValue, total: OnboardingPage.allCases.count)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button(action: page.isLast ? onDismiss : onAdvance) {
                    Text(page.isLast ? "Enter the Cascade" : "Next")
                        .frame(width: 184)
                }
                .controlSize(.large)
                .applyGlassStyle(isProminent: true, tint: .blue)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
