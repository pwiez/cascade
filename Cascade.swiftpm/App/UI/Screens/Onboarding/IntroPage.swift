import SwiftUI

/// First onboarding page: what Cascade is, and what the shapes on screen mean.
struct IntroPage: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 60

    var body: some View {
        HStack(alignment: .center, spacing: 64) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Cascade")
                    .font(.system(size: titleSize, weight: .bold))

                Text("A real-time Kessler Syndrome simulator")
                    .font(.title2)
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
                OnboardingLegendItem(icon: "cube.fill", color: .green,
                                     title: "Satellites", detail: "The green cubes orbiting Earth")
                OnboardingLegendItem(icon: "pyramid.fill", color: .red,
                                     title: "Debris", detail: "Fragments thrown off by collisions")
            }
            .frame(width: 260, alignment: .leading)
        }
    }
}
