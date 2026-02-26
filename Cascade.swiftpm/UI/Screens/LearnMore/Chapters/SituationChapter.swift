import SwiftUI

struct SituationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Timeline of Key Events")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("The accumulation of orbital debris is not a recent phenomenon. It started all the way back in the 1950s and has been increasing ever since. Several pivotal events injected massive debris populations into heavily used orbital regions, each one demonstrating the fragility of the orbital commons.")
                
                TimelineVertical()
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Current Orbital Population")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Space surveillance networks — primarily the U.S. Space Surveillance Network and ESA's Space Debris Office — continuously track objects larger than 10 cm in Low Earth Orbit. The cataloged population has grown dramatically, with sharp inflections corresponding to fragmentation events and increases in satellite launches, such as in the early 2020s.")
                
                ScientificCard { DebrisChart() }
            }
            
            Divider().cascadeDivider()
            
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Operational Impacts")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("As you learned in this and the previous chapters, the growing debris population has measurable consequences for active missions. Collision avoidance maneuvers are becoming routine, consuming propellant and reducing mission lifetime, and increasing risk to astronauts.")
                
                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "45k +",
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
                    title: "On conjunctions and avoidance maneuvers",
                    bodyText: "Conjunction is the name for the event of an object passing dangerously close to another in orbit. Every tracked object's trajectory is projected forward and compared against all others. When the predicted miss distance falls below a threshold (typically a few hundred meters), operators have to decide whether to execute an avoidance maneuver, which consumes irreplaceable fuel and disrupts mission operations. Avoidance maneuvers are common with companies and organizations that inject a great number of satellites into similar orbital altitudes. Thanks to the debris problem, it's becoming common even for the ISS, which is a bigger target. It currently performs about 4 of them every year.",
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit): \(label)")
    }
}
