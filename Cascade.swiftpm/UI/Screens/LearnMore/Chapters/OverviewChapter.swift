import SwiftUI

struct OverviewChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
        
            DefinitionCallout(
                term: "Kessler Syndrome",
                definition: "A scenario where the density of objects such as satellites and debris in different ranges of Earth's orbit becomes so high that it triggers a self-sustaining cascade of collisions. Each successive collision produces hundreds to thousands of fragments, which then destroy other objects in an expanding chain reaction. This effect can end up rendering entire orbits much harder to safely use for a very long time.",
                source: "Kessler & Cour-Palais, 1978"
            )
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Why is learning about this important?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                TextParagraph("Nowadays, our life relies on satellites: GPS, weather forecasting, global internet, disaster warnings, and more. All of these require not only safe access to Low Earth Orbit, but long-lasting orbital safety. If collision rates cross a critical threshold, that entire region of space could become a lethal minefield for everything else in it, rendering it unusable for generations. Cascade shows that this isn't triggered by a single massive explosion, but instead a slow, compounding chain reaction.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("What Cascade can teach you")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 12) {
                    LearningObjective(text: "Understand why Kessler Syndrome is dangerous for humanity")
                    LearningObjective(text: "See how extreme orbital speeds can turn tiny debris into lethal weapons")
                    LearningObjective(text: "Visualize how debris clouds can spread around the globe")
                    LearningObjective(text: "Recognize space as a finite environment that requires active cleanup and protection")
                    LearningObjective(text: "Understand that the protection of the environment is a duty that extends to space, not just Earth")
                }
            }
        }
    }
}
