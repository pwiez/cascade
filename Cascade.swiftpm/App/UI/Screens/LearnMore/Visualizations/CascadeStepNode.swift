import SwiftUI

/// One icon-and-caption node of the cascade diagram.
struct CascadeStepNode: View {
    let step: CascadeStep

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: step.icon)
                .font(.title3)
                .foregroundStyle(step.color)

            Text(step.title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
