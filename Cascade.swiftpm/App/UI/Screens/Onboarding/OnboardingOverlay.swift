//
//  OnboardingOverlay.swift
//  Cascade
//
//  Created by Pedro Wiezel on 21/02/26.
//

import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var page: OnboardingPage = .intro

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.8), .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip", action: onDismiss)
                        .controlSize(.large)
                        .applyGlassStyle(isProminent: false, tint: nil)
                }

                Spacer(minLength: 16)

                ZStack {
                    switch page {
                    case .intro: IntroPage().transition(pageTransition)
                    case .controls: ControlsPage().transition(pageTransition)
                    }
                }
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 16)

                OnboardingNavigationBar(
                    page: page,
                    onBack: back,
                    onAdvance: advance,
                    onDismiss: onDismiss
                )
            }
            .padding(.horizontal, 72)
            .padding(.top, 28)
            .padding(.bottom, 36)
        }
        .contentShape(.rect)
        .gesture(swipe)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) { appeared = true }
        }
    }

    private var pageTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 12))
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                if value.translation.width < -50 {
                    advance()
                } else if value.translation.width > 50 {
                    back()
                }
            }
    }

    private func advance() {
        guard let next = page.next else { return }
        withAnimation(.easeInOut(duration: 0.3)) { page = next }
    }

    private func back() {
        guard let previous = page.previous else { return }
        withAnimation(.easeInOut(duration: 0.3)) { page = previous }
    }
}
