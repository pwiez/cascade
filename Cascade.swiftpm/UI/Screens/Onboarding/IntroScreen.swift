//
//  IntroScreen.swift
//  Cascade
//
//  Created by Pedro Wiezel on 21/02/26.
//

import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var page = 0

    private let pageCount = 2

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.8), .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 16)

                ZStack {
                    if page == 0 {
                        IntroPage().transition(pageTransition)
                    } else {
                        ControlsPage().transition(pageTransition)
                    }
                }
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 16)

                bottomBar
            }
            .padding(.horizontal, 72)
            .padding(.top, 28)
            .padding(.bottom, 36)
        }
        .contentShape(Rectangle())
        .gesture(swipe)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) { appeared = true }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip", action: onDismiss)
                .controlSize(.large)
                .applyGlassStyle(isProminent: false, tint: nil)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            HStack {
                if page > 0 {
                    Button {
                        back()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .controlSize(.large)
                    .applyGlassStyle(isProminent: false, tint: nil)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)

            PageDots(current: page, total: pageCount)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button {
                    page < pageCount - 1 ? advance() : onDismiss()
                } label: {
                    Text(page < pageCount - 1 ? "Next" : "Enter the Cascade")
                        .frame(width: 184)
                }
                .controlSize(.large)
                .applyGlassStyle(isProminent: true, tint: .blue)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var pageTransition: AnyTransition {
        .opacity.combined(with: .offset(y: 12))
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                if value.translation.width < -50 { advance() }
                else if value.translation.width > 50 { back() }
            }
    }

    private func advance() {
        guard page < pageCount - 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
    }

    private func back() {
        guard page > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { page -= 1 }
    }
}

private struct IntroPage: View {
    var body: some View {
        HStack(alignment: .center, spacing: 64) {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "Welcome to", color: .blue)
                    .padding(.bottom, 10)

                Text("Cascade")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.primary)

                Text("A real-time Kessler Syndrome simulator")
                    .font(.title2.weight(.regular))
                    .foregroundStyle(DesignTokens.dimText)

                Text("A runaway chain reaction: once orbital collisions grow frequent enough, the debris they create triggers still more collisions. Play with the simulation, and see how impacts snowball into a cascade that fills an entire orbit with shrapnel.")
                    .font(.body)
                    .foregroundStyle(DesignTokens.bodyText)
                    .padding(.top, 24)
                    .lineSpacing(DesignTokens.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 28) {
                legendItem(icon: "cube.fill", color: .green,
                           title: "Satellites", detail: "The green cubes orbiting Earth")
                legendItem(icon: "pyramid.fill", color: .red,
                           title: "Debris", detail: "Fragments thrown off by collisions")
            }
            .frame(width: 260, alignment: .leading)
        }
    }

    private func legendItem(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ControlsPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Controls")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.primary)

            HStack(alignment: .top, spacing: 56) {
                controlColumn(label: "Simulation", rows: [
                    .init("burst.fill", .red, "Detonate", "Explode a random satellite"),
                    .init("arrow.triangle.2.circlepath", .orange, "Restart", "Reset the simulation"),
                    .init("play.fill", .green, "Play / Pause", "Start or pause time"),
                    .init("camera.metering.center.weighted", .primary, "Reset Camera", "Recenter the view"),
                    .init("gearshape.fill", .primary, "Settings", "Visuals and parameters")
                ])

                controlColumn(label: "Camera", rows: [
                    .init("hand.draw.fill", .primary, "Drag", "Orbit the camera around Earth"),
                    .init("hand.pinch.fill", .primary, "Pinch", "Zoom in and out")
                ])
            }
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
    }

    private func controlColumn(label: String, rows: [ControlItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: label)
                .padding(.bottom, 12)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index != 0 {
                    Rectangle().fill(DesignTokens.hairline).frame(height: 1)
                }
                ControlRow(item: row)
                    .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PageDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index == current ? 1 : 0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(total)")
    }
}

private struct ControlItem {
    let icon: String
    let tint: Color
    let name: String
    let detail: String

    init(_ icon: String, _ tint: Color, _ name: String, _ detail: String) {
        self.icon = icon
        self.tint = tint
        self.name = name
        self.detail = detail
    }
}

private struct ControlRow: View {
    let item: ControlItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: item.icon)
                .font(.body)
                .imageScale(.medium)
                .foregroundStyle(item.tint)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
