//
//  SimulationButton.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct SimulationButton: View {
    let icon: String
    let action: () -> Void
    let isProminent: Bool
    var tint: Color?
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
        .modifier(GlassStyleModifier(isProminent: isProminent, tint: tint))
    }
}

struct GlassStyleModifier: ViewModifier {
    var isProminent: Bool
    var tint: Color?

    func body(content: Content) -> some View {
        if isProminent {
            content.buttonStyle(.glassProminent)
                .tint(tint)
        } else {
            content.buttonStyle(.glass)
        }
    }
}
