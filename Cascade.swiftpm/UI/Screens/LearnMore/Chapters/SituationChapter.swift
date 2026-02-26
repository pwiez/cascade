import SwiftUI

struct SituationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Timeline of Key Events")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("Orbital debris accumulation started in the 1950s. It has grown ever since. A few pivotal events injected massive debris clouds into heavily used orbits. Each event proved how fragile the orbital environment actually is.")
                
                TimelineVertical()
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Current Orbital Population")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("The U.S. Space Surveillance Network and ESA continuously track objects larger than 10 cm. The cataloged population has grown dramatically. The sharp spikes in the data map directly to weapon tests, accidental collisions, and the recent boom in mega-constellations.")
                
                ScientificCard { DebrisChart() }
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Operational Impacts")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("This growing debris cloud has immediate consequences for active missions. Collision avoidance maneuvers are now routine. Every maneuver burns irreplaceable fuel, shortens a satellite's lifespan, and puts human crews at risk.")
                
                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "55k +",
                        unit: "tracked",
                        label: "objects in orbit",
                        icon: "",
                        accent: .red
                    )
            
                    OperationalStatCard(
                        value: "~14.5k",
                        unit: "operational satellites",
                        label: "currently orbiting Earth",
                        icon: "",
                        accent: .purple
                    )
                }

                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "1.2 million+",
                        unit: "non-tracked debris",
                        label: "that are very dangerous (1cm - 10cm)",
                        icon: "",
                        accent: .yellow
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
                    title: "Conjunctions and Avoidance",
                    bodyText: "A conjunction happens when two objects pass dangerously close to each other. Operators project trajectories forward. If the predicted miss distance is too tight, they execute an avoidance maneuver. The International Space Station currently performs about four of these maneuvers every year.",
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
                    .foregroundStyle(.white)
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
