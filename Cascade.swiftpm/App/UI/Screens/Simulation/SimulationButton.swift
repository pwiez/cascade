import SwiftUI

/// A round control in the simulation's left-hand rail.
///
/// The background is drawn here rather than left to `.buttonStyle(.glass)` and
/// `.glassProminent`. Those two pad their labels by different amounts and pick
/// their own border shapes, so a prominent button lands visibly larger than the
/// plain ones beside it — and `buttonBorderShape` doesn't reliably override it.
/// Owning the frame and the shape is the only way to guarantee the rail is
/// uniform, so the button itself is `.plain` and everything visual happens on
/// the label.
struct SimulationButton: View {
    let title: String
    let icon: String
    let hint: String
    var isProminent = false
    var tint: Color?
    let action: () -> Void

    /// One diameter for every button in the rail, comfortably past Apple's 44pt
    /// minimum tap target.
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
    /// Liquid Glass where the OS has it, a material or a solid fill where it
    /// doesn't — always in the same circle, at the size the caller set.
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
