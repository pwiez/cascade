//
//  SimulationButton.swift
//  Cascade
//
//  Created by Pedro Wiezel on 16/02/26.
//

import SwiftUI

struct SimulationButton: View {
    let title: String
    let icon: String
    let hint: String
    var isProminent = false
    var tint: Color?
    let action: () -> Void

    private let diameter: CGFloat = 52

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(isProminent ? Color.white : Color.primary)
                .frame(width: diameter, height: diameter)
                .simulationButtonBackground(isProminent: isProminent, tint: tint)
        }
        .buttonStyle(.plain)
        .accessibilityHint(hint)
    }
}

private extension View {
    @ViewBuilder
    func simulationButtonBackground(isProminent: Bool, tint: Color?) -> some View {
        if #available(iOS 26, *) {
            if isProminent, let tint {
                glassEffect(.regular.tint(tint), in: .circle)
            } else {
                glassEffect(.regular, in: .circle)
            }
        } else if isProminent {
            background(tint ?? .accentColor, in: .circle)
        } else {
            background(.ultraThinMaterial, in: .circle)
        }
    }
}
