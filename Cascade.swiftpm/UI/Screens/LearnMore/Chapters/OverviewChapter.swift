import SwiftUI

struct OverviewChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
        
            DefinitionCallout(
                term: "Kessler Syndrome",
                definition: "A scenario where the density of objects in Low Earth Orbit triggers a self-sustaining cascade of collisions. Each impact produces thousands of fragments, which then destroy other objects in an exponential chain reaction.",
                source: "Kessler & Cour-Palais, 1978"
            )
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Why is learning about this important?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                TextParagraph("Modern life relies on satellites: GPS, weather forecasting, global internet, and disaster warnings. All of these require safe access to Low Earth Orbit. If collision rates cross a critical threshold, that entire region of space could become a lethal minefield, rendering it unusable for generations. As Cascade shows, this isn't triggered by a single massive explosion. It’s a slow, compounding chain reaction.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("What Cascade can teach you")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    LearningObjective(text: "Understand why collision cascades become unstoppable")
                    LearningObjective(text: "See how extreme orbital speeds turn tiny debris into lethal weapons")
                    LearningObjective(text: "Visualize debris clouds spreading around the globe")
                    LearningObjective(text: "Recognize space as a finite environment that requires active cleanup and protection")
                }
            }
        }
    }
}
