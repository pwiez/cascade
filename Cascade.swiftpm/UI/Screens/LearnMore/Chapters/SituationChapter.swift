import SwiftUI

struct SituationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            
            VStack(alignment: .leading, spacing: 24) {
                TextParagraph("Orbital debris accumulation is not new. It started all the way back in the 1950s and has grown ever since. A few pivotal events injected massive amounts of space junk into heavily used orbits, and each of those events proved time and again how fragile the orbital environment can be.")
                
                TimelineVertical()
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Current Orbital Population")
                    .font(.title2.weight(.bold)).foregroundStyle(.primary)
                
                TextParagraph("The sharp spikes in this chart map directly to weapon tests, accidental collisions, and the recent boom in mega-constellations that you just learned about in the timeline.")
                
                ScientificCard { DebrisChart() }
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Operational Impacts")
                    .font(.title2.weight(.bold)).foregroundStyle(.primary)
                
                TextParagraph("This growing danger causes immediate consequences for active missions. Collision avoidance maneuvers are now routine, and every one of those burns irreplaceable fuel, may shorten a craft's lifespan, and sometimes can put human crews at risk.")
                
                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "55k +",
                        unit: "tracked",
                        label: "objects in orbit",
                        icon: "",
                        accent: .red
                    )
                    
                    OperationalStatCard(
                        value: "40+",
                        unit: "avoidance maneuvers",
                        label: "the ISS has had to do since 1998",
                        icon: "",
                        accent: .blue
                    )
                }
                
                KeyConceptBox(
                    title: "Conjunctions",
                    bodyText: "A conjunction happens when two objects pass dangerously close to each other in space. Operators project the trajectories of dangerous tracked objects forward, and if the predicted miss distance between them is too tight, they execute an avoidance maneuver. The International Space Station currently performs about four of these maneuvers every year.",
                    icon: "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
        }
    }
}

struct OperationalStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CascadeTheme.mutedText)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(CascadeTheme.mutedText)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CascadeTheme.compactPadding)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(accent.opacity(0.12), lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(unit): \(label)")
    }
}
