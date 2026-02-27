import SwiftUI

struct RemediationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            TextParagraph("As you learned in previous chapters, the situation is pretty grim, but it is fixable. We need to do three things: stop making new debris, responsibly dispose of dead satellites, and drag the most dangerous junk out of orbit before it gets hit.")
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Atmospheric Drag")
                    .font(.title2.weight(.bold)).foregroundStyle(.primary)
                
                TextParagraph("This is our main ally in this. Did you know Earth's atmosphere does not just end when you get to space? Instead, it tapers off gradually. Gas molecules at very high altitudes are few and far between, but they exert a persistent drag force on orbiting objects. Over time, this drag lowers an object's altitude until it burns up in the thicker atmosphere.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("How long does it take for an object to deorbit through drag forces?")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.dimText)
                        
                        VStack(spacing: 12) {
                            DragLifetimeRow(altitude: "300 km", lifetime: "Weeks to months", intensity: 1.0, color: .green)
                            DragLifetimeRow(altitude: "400 km", lifetime: "~1 year", intensity: 0.75, color: .green)
                            DragLifetimeRow(altitude: "600 km", lifetime: "~25 years", intensity: 0.45, color: .yellow)
                            DragLifetimeRow(altitude: "800 km", lifetime: "~100–200 years", intensity: 0.10, color: .orange)
                            DragLifetimeRow(altitude: "1,000 km", lifetime: "~1,000+ years", intensity: 0.02, color: .red)
                        }
                    }
                }
                .padding(.vertical)
                
                TextParagraph("Below 600 km, drag can clear most debris within a few decades. The real challenge lies in higher orbits, where drag is negligible and debris can persist for centuries.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Active Removal Technologies")
                    .font(.title2.weight(.bold)).foregroundStyle(.primary)
                
                TextParagraph("Atmospheric drag is powerful, but it is insufficient. We need engineered interventions to clear higher orbits or at least make them safer. Several approaches are currently under development. Some of them may seem like they came out of science fiction, but they are very real ideas being researched and tested currently.")
                
                VStack(spacing: 20) {
                    StrategyCard(
                        title: "Graveyard Orbits",
                        icon: "arrowshape.up.fill",
                        description: "Instead of deorbiting, operators can use the satellite's very last reserves of propellant to push it about 300 kilometers higher into a graveyard orbit, also known as a disposal orbit. This safely removes it from the highly congested operational lanes. It's like parking the satellite permanently out of the way. This is done for satellites in GEO, where speeds are lower and graveyard orbits are safer.",
                    )
                    
                    StrategyCard(
                        title: "Drag Augmentation",
                        icon: "wind",
                        description: "Deployable sails or inflatable structures dramatically increase a satellite's cross-sectional area, which in turn increases its susceptibility to drag forces. Since they can be integrated in craft design far before it is even launched, this is a mechanical and preventive measure which is quite effective.",
                    )
                    
                    StrategyCard(
                        title: "Harpoons & Nets",
                        icon: "lasso",
                        description: "A chaser spacecraft approaches a defunct satellite or rocket body and secures it using a tethered harpoon or a deployable net. The chaser then fires its engines to deorbit the captured debris. The RemoveDEBRIS mission demonstrated net capture in 2018. It was supposed to demonstrate the drag sail technique as well, but the drag sails failed to deploy. ESA's ClearSpace-1 mission plans to perform the first full-scale removal operation, deorbiting ESA's own PROBA-1 satellite. It is planned to launch in 2029.",
                    )
                    
                    StrategyCard(
                        title: "Laser Ablation",
                        icon: "dot.radiowaves.left.and.right",
                        description: "Ground-based or orbital lasers target the surface of a piece of debris. The focused laser energy vaporizes a tiny amount of material, and the ejected vapor acts as a miniature thruster. Over time, with repeated laser passes, the object can be slowed enough to deorbit or be pushed up into a safer orbit. Cost-wise, this is a very effective solution since it does not necessarily involve launching specialized crafts into space.",
                    )
                    
                    StrategyCard(
                        title: "Magnetic Stabilization & Braking",
                        icon: "gyroscope",
                        description: "Tumbling debris is very dangerous to approach. A spacecraft can approach the objects with magnetic tugs, which generate rotating magnetic fields. These fields induce eddy currents in the target's metal hull, creating drag forces from a safe distance. These forces can stabilize the debris' rotation and slow it down over time. This technology is highly experimental and currently being researched.",
                    )
                }
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("The 25-Year Guideline")
                    .font(.title2.weight(.bold)).foregroundStyle(.primary)
                
                TextParagraph("The Inter-Agency Space Debris Coordination Committee (IADC) recommends that all satellites in Low Earth Orbit deorbit within 25 years after a mission ends. So, if a satellite reaches its mission end in 2030 it should be deorbited at most by 2055. In the 2020s, the U.S. Federal Communications Commission adopted a stricter 5-year rule. However, compliance remains voluntary for many global operators outside of the U.S.")
            }
        }
    }
}

struct DragLifetimeRow: View {
    let altitude: String
    let lifetime: String
    let intensity: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(altitude)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .frame(width: 70, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CascadeTheme.trackColor)
                    Capsule()
                        .fill(color.opacity(0.6))
                        .frame(width: max(geo.size.width * intensity, CascadeTheme.trackHeight))
                }
            }
            .frame(height: CascadeTheme.trackHeight + 1)
            .clipShape(Capsule())
            
            Text(lifetime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(CascadeTheme.mutedText)
                .frame(width: 120, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("At \(altitude): debris lifetime approximately \(lifetime)")
    }
}

struct StrategyCard: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                ThemedIcon(systemName: icon, color: .blue, isCircle: true)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            Divider().overlay(Color.primary.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 16) {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
            }
        }
        .padding(CascadeTheme.cardPadding)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .contain)
    }
}
