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
        .applyGlassStyle(isProminent: isProminent, tint: tint)
    }
}
